package com.budgetella.app.data.billing

import android.app.Activity
import android.content.Context
import android.util.Log
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClient.ProductType
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.android.billingclient.api.acknowledgePurchase
import com.android.billingclient.api.queryProductDetails
import com.android.billingclient.api.queryPurchasesAsync
import com.budgetella.app.data.model.SubscriptionType
import com.budgetella.app.data.repository.SubscriptionRepository
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.MetadataChanges
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.math.min
import kotlin.math.pow

/**
 * Native Google Play Billing v7 implementation — Android parity of the iOS
 * [com.budgetella.app] StoreKit 2 wrapper.
 *
 * Lifecycle: app-scoped singleton. `BillingClient` is created once at
 * construction, connects on demand, and reconnects with exponential backoff
 * if the service drops out (Play services updates, low-memory kills, etc.).
 *
 * Entitlement model:
 *  - **Source of truth:** Firestore `users/{uid}` document. Fields mirror
 *    Stripe webhook output so iOS, Android, and web all converge on a single
 *    schema (`isPremium`, `subscriptionType`, `subscriptionId`,
 *    `subscriptionStatus`, `subscriptionEndDate`).
 *  - **Optimistic write:** after a successful Play purchase the client writes
 *    `isPremium=true` to Firestore immediately so the UI flips without waiting
 *    for the RTDN webhook. The webhook then reconciles the authoritative
 *    `subscriptionEndDate` from the Play Developer API.
 *
 * Why a UID is attached to every purchase:
 *  - `BillingFlowParams.Builder().setObfuscatedAccountId(firebaseUid)` lets the
 *    Cloud Function RTDN handler resolve a Play purchase back to a Firestore
 *    user without a separate token table. iOS does the equivalent via
 *    `Transaction.appAccountToken`.
 */
@Singleton
class PlayBillingSubscriptionRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val firestore: FirebaseFirestore,
) : SubscriptionRepository, PurchasesUpdatedListener {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val billingClient: BillingClient = BillingClient
        .newBuilder(context)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()  // Required for the lifetime INAPP product.
                .build()
        )
        .build()

    private val productCache = MutableStateFlow<List<ProductDetails>>(emptyList())

    /** Latest Firebase UID known to the repository — set on every Firestore observe. */
    @Volatile private var lastKnownUid: String? = null

    @Volatile private var connectionAttempt: Int = 0
    @Volatile private var isConnecting: Boolean = false

    init {
        ensureConnected()
    }

    // ── Connection ─────────────────────────────────────────────────────────

    private fun ensureConnected() {
        if (billingClient.isReady || isConnecting) return
        isConnecting = true
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                isConnecting = false
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    connectionAttempt = 0
                    scope.launch {
                        refreshProducts()
                        // Reconcile any purchase the user completed offline.
                        runCatching { reconcilePurchases() }
                            .onFailure { Log.w(TAG, "reconcilePurchases failed", it) }
                    }
                } else {
                    Log.w(TAG, "Billing setup failed: ${result.responseCode} ${result.debugMessage}")
                    scheduleReconnect()
                }
            }

            override fun onBillingServiceDisconnected() {
                isConnecting = false
                scheduleReconnect()
            }
        })
    }

    private fun scheduleReconnect() {
        connectionAttempt = min(connectionAttempt + 1, MAX_RECONNECT_EXPONENT)
        val delayMs = (BASE_RECONNECT_DELAY_MS * 2.0.pow(connectionAttempt)).toLong()
        scope.launch {
            kotlinx.coroutines.delay(delayMs)
            ensureConnected()
        }
    }

    // ── Product catalogue ──────────────────────────────────────────────────

    override fun observeProducts(): Flow<List<ProductDetails>> = productCache.asStateFlow()

    private suspend fun refreshProducts() {
        if (!billingClient.isReady) return

        val subs = queryDetails(BillingProducts.SUBSCRIPTION_IDS, ProductType.SUBS)
        val inApp = queryDetails(BillingProducts.ONE_TIME_IDS, ProductType.INAPP)
        productCache.value = subs + inApp
    }

    private suspend fun queryDetails(ids: List<String>, type: String): List<ProductDetails> {
        if (ids.isEmpty()) return emptyList()
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                ids.map { id ->
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(id)
                        .setProductType(type)
                        .build()
                }
            )
            .build()
        val result = billingClient.queryProductDetails(params)
        if (result.billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
            Log.w(TAG, "queryProductDetails($type) failed: ${result.billingResult.debugMessage}")
        }
        return result.productDetailsList.orEmpty()
    }

    // ── Purchase flow ──────────────────────────────────────────────────────

    override suspend fun startPurchase(
        activity: Activity,
        productId: String,
        offerToken: String?,
    ): Result<Unit> = runCatching {
        ensureConnected()
        if (!billingClient.isReady) {
            // Wait briefly for the connection to finish; surface a friendly error if it doesn't.
            repeat(20) {
                if (billingClient.isReady) return@repeat
                kotlinx.coroutines.delay(100)
            }
        }
        if (!billingClient.isReady) {
            error("Play Billing service unavailable. Try again in a moment.")
        }

        val details = productCache.value.firstOrNull { it.productId == productId }
            ?: refreshProducts().let { productCache.value.firstOrNull { it.productId == productId } }
            ?: error("Product $productId not found in Play. Confirm the listing is active.")

        val productParamsBuilder = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(details)

        // Subscriptions require an offer token; INAPP products do not.
        if (details.productType == ProductType.SUBS) {
            val token = offerToken
                ?: details.subscriptionOfferDetails
                    ?.firstOrNull()
                    ?.offerToken
                ?: error("No subscription offer token available for $productId.")
            productParamsBuilder.setOfferToken(token)
        }

        val uid = lastKnownUid
        val flowParamsBuilder = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(productParamsBuilder.build()))

        if (!uid.isNullOrBlank()) {
            // Lets the RTDN Cloud Function map a Play purchase back to this Firebase user.
            flowParamsBuilder.setObfuscatedAccountId(uid)
        }

        val launchResult = billingClient.launchBillingFlow(activity, flowParamsBuilder.build())
        if (launchResult.responseCode != BillingClient.BillingResponseCode.OK) {
            error("launchBillingFlow failed: ${launchResult.debugMessage}")
        }
    }

    // PurchasesUpdatedListener — Play hands new purchases back here.
    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    scope.launch { processPurchase(purchase) }
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                Log.d(TAG, "User cancelled purchase flow.")
            }
            else -> {
                Log.w(TAG, "Purchase update error: ${result.responseCode} ${result.debugMessage}")
            }
        }
    }

    private suspend fun processPurchase(purchase: Purchase) {
        if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED) {
            // PENDING (e.g. cash payment) — leave entitlement off. RTDN will
            // emit SUBSCRIPTION_PURCHASED / ONE_TIME_PRODUCT_PURCHASED once it
            // settles.
            return
        }

        // Acknowledge within 3 days — Play auto-refunds otherwise.
        if (!purchase.isAcknowledged) {
            val ackResult = billingClient.acknowledgePurchase(
                AcknowledgePurchaseParams.newBuilder()
                    .setPurchaseToken(purchase.purchaseToken)
                    .build()
            )
            if (ackResult.responseCode != BillingClient.BillingResponseCode.OK) {
                Log.w(TAG, "acknowledgePurchase failed: ${ackResult.debugMessage}")
            }
        }

        // Optimistic Firestore write so the UI flips immediately. RTDN
        // reconciles authoritative `subscriptionEndDate` from the Play
        // Developer API shortly after.
        val uid = purchase.accountIdentifiers?.obfuscatedAccountId ?: lastKnownUid
        if (uid.isNullOrBlank()) {
            Log.w(TAG, "Purchase without a UID — RTDN will reconcile when the user is known.")
            return
        }

        val productId = purchase.products.firstOrNull() ?: return
        val tier = BillingProducts.toCanonicalTier(productId)
        val updates = buildMap<String, Any?> {
            put("isPremium", true)
            put("subscriptionType", tier.raw)
            put("subscriptionId", purchase.purchaseToken)
            put("subscriptionStatus", "active")
            put("subscriptionPlatform", "android")
            put("subscriptionProductId", productId)
            put("subscriptionUpdatedAt", FieldValue.serverTimestamp())
            if (tier == SubscriptionType.Lifetime) {
                put("subscriptionEndDate", null)
            }
            // For subscriptions, leave `subscriptionEndDate` for RTDN to set.
        }

        runCatching {
            firestore.collection("users").document(uid)
                .set(updates, com.google.firebase.firestore.SetOptions.merge())
                .await()
        }.onFailure {
            Log.w(TAG, "Optimistic Firestore write failed", it)
        }
    }

    // ── Restore ────────────────────────────────────────────────────────────

    override suspend fun restorePurchases(): Result<Unit> = runCatching {
        ensureConnected()
        reconcilePurchases()
    }

    private suspend fun reconcilePurchases() {
        if (!billingClient.isReady) return

        val subs = queryPurchases(ProductType.SUBS)
        val inApp = queryPurchases(ProductType.INAPP)
        (subs + inApp).forEach { processPurchase(it) }
    }

    private suspend fun queryPurchases(type: String): List<Purchase> {
        val params = QueryPurchasesParams.newBuilder().setProductType(type).build()
        val result = billingClient.queryPurchasesAsync(params)
        if (result.billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
            Log.w(TAG, "queryPurchases($type) failed: ${result.billingResult.debugMessage}")
        }
        return result.purchasesList
    }

    // ── Entitlement observation ────────────────────────────────────────────

    override fun observeIsPremium(uid: String): Flow<Boolean> = callbackFlow {
        if (uid.isBlank()) {
            trySend(false)
            awaitClose { }
            return@callbackFlow
        }
        lastKnownUid = uid

        val docRef = firestore.collection("users").document(uid)
        val registration: ListenerRegistration = docRef
            .addSnapshotListener(MetadataChanges.EXCLUDE) { snapshot, error ->
                if (error != null) {
                    Log.w(TAG, "users/$uid snapshot error", error)
                    trySend(false)
                    return@addSnapshotListener
                }
                trySend(evaluateEntitlement(snapshot?.data))
            }

        awaitClose { registration.remove() }
    }
        .distinctUntilChanged()
        .flowOn(Dispatchers.IO)

    private fun evaluateEntitlement(data: Map<String, Any?>?): Boolean {
        if (data == null) return false
        val isPremium = data["isPremium"] as? Boolean ?: return false
        if (!isPremium) return false

        val tier = SubscriptionType.fromRaw(data["subscriptionType"] as? String)
        if (tier == SubscriptionType.Lifetime) return true

        val end = when (val raw = data["subscriptionEndDate"]) {
            is com.google.firebase.Timestamp -> raw.toDate().time
            is Number -> raw.toLong()
            else -> null
        } ?: return true // subscription with no end date yet — RTDN will fill it; treat as active

        return end >= System.currentTimeMillis()
    }

    private companion object {
        const val TAG = "PlayBilling"
        const val BASE_RECONNECT_DELAY_MS = 1_000L
        const val MAX_RECONNECT_EXPONENT = 6  // ~64s ceiling
    }
}

/**
 * Suspending variant of [BillingClient.startConnection] — used in places where
 * an explicit ready-state is preferred to the listener pattern. Kept here for
 * future test scaffolding; the main repo uses the callback form so it can
 * reconnect on its own schedule.
 */
@Suppress("unused")
internal suspend fun BillingClient.connectSuspending(): BillingResult =
    suspendCancellableCoroutine { cont ->
        startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (cont.isActive) cont.resume(result)
            }

            override fun onBillingServiceDisconnected() {
                // Surfaced via the next call; nothing to do here.
            }
        })
    }
