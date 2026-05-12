package com.budgetella.app.data.repository

import android.app.Activity
import com.android.billingclient.api.ProductDetails
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Subscription / premium-entitlement boundary.
 *
 * Mirrors the iOS `SubscriptionService` API surface (StoreKit 2). The
 * production implementation is [com.budgetella.app.data.billing.PlayBillingSubscriptionRepository];
 * [StubSubscriptionRepository] is kept around for Compose previews and unit
 * tests that don't want to spin up a real `BillingClient`.
 *
 * Contract:
 *  - [observeIsPremium] is the single source of truth for "should I unlock
 *    premium features?". Reads from Firestore `users/{uid}` so iOS and Android
 *    converge on the same entitlement state regardless of which platform paid.
 *  - [observeProducts] streams localized [ProductDetails] objects from Play.
 *    The paywall reads `formattedPrice` off these — never hard-code prices.
 *  - [startPurchase] launches the Play Billing flow for [productId]. The
 *    caller must pass the current `Activity`; Play requires an activity ref
 *    for the purchase sheet.
 *  - [restorePurchases] re-queries Play for prior purchases (subscriptions
 *    + non-consumables) and forces a Firestore reconcile.
 */
interface SubscriptionRepository {

    /** True once the user has an active premium entitlement (Firestore-backed). */
    fun observeIsPremium(uid: String): Flow<Boolean>

    /** Stream of cached [ProductDetails] for every paywall product. */
    fun observeProducts(): Flow<List<ProductDetails>>

    /**
     * Launch the Play Billing flow for [productId].
     *
     * @param offerToken Required for subscriptions (`subscriptionOfferDetails.offerToken`).
     *   `null` is valid for one-time (INAPP) products like `premium_lifetime`.
     */
    suspend fun startPurchase(
        activity: Activity,
        productId: String,
        offerToken: String? = null,
    ): Result<Unit>

    /** Re-query Play for prior purchases and reconcile entitlement. */
    suspend fun restorePurchases(): Result<Unit>
}

/**
 * Test / preview fallback — every call resolves to "not premium / not implemented".
 * Production code wires [com.budgetella.app.data.billing.PlayBillingSubscriptionRepository]
 * via [com.budgetella.app.di.SubscriptionModule].
 */
@Singleton
class StubSubscriptionRepository @Inject constructor() : SubscriptionRepository {

    override fun observeIsPremium(uid: String): Flow<Boolean> = flowOf(false)

    override fun observeProducts(): Flow<List<ProductDetails>> = flowOf(emptyList())

    override suspend fun startPurchase(
        activity: Activity,
        productId: String,
        offerToken: String?,
    ): Result<Unit> = Result.failure(NotImplementedError("Stub repository — wire PlayBillingSubscriptionRepository."))

    override suspend fun restorePurchases(): Result<Unit> = Result.success(Unit)
}
