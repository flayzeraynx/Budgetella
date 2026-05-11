package com.budgetella.app.data.repository

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Subscription / premium-entitlement boundary.
 *
 * Stub for v1 — Play Billing isn't wired yet. The interface exists so call
 * sites (PaywallScreen, feature-gated insights, settings "Manage subscription")
 * can compile against a stable shape, and we can swap in a Play Billing-backed
 * impl behind a single Hilt binding when M8.1 lands.
 *
 * Contract:
 *  - [observeIsPremium] is the single source of truth for "should I unlock
 *    premium features?". V1 always returns false.
 *  - [startPurchase] is the entry point the paywall CTA will call once
 *    BillingClient is integrated. Today it surfaces NotImplementedError so the
 *    UI can show a friendly "coming soon" message.
 *  - [restorePurchases] is a no-op stub — Play handles entitlement restoration
 *    automatically once BillingClient is set up, so this is here only for the
 *    "Restore purchases" affordance on the paywall.
 */
interface SubscriptionRepository {

    /** True once the user has an active premium entitlement. */
    fun observeIsPremium(uid: String): Flow<Boolean>

    /** Launch the Play Billing flow for [productId]. Stubbed to failure today. */
    suspend fun startPurchase(productId: String): Result<Unit>

    /** Query Play Billing for prior purchases. Stubbed to no-op success. */
    suspend fun restorePurchases(): Result<Unit>
}

/**
 * V1 stub — every call resolves to "not premium / not implemented".
 *
 * TODO(M8.1): replace with PlayBillingSubscriptionRepository using
 * com.android.billingclient:billing-ktx. Wire entitlement state via
 * BillingClient.queryPurchasesAsync and persist server-side via a
 * Cloud Function so iOS and Android share the same source of truth.
 */
@Singleton
class StubSubscriptionRepository @Inject constructor() : SubscriptionRepository {

    override fun observeIsPremium(uid: String): Flow<Boolean> = flowOf(false)

    override suspend fun startPurchase(productId: String): Result<Unit> =
        Result.failure(NotImplementedError("Play Billing not wired yet — paywall stub."))

    override suspend fun restorePurchases(): Result<Unit> = Result.success(Unit)
}
