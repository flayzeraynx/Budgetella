package com.budgetella.app.data.billing

import com.budgetella.app.data.model.SubscriptionType

/**
 * Single source of truth for Play Billing product identifiers.
 *
 * iOS uses StoreKit product IDs prefixed with the bundle ID
 * (`com.ozankilic.budgetella.premium.*`). Android Play Console uses short,
 * unprefixed IDs (Play requires lowercase + underscore, no dots). To keep
 * the Firestore `users/{uid}` schema platform-agnostic, both apps write a
 * **canonical** [SubscriptionType] (`monthly` / `yearly` / `lifetime`) into
 * the `subscriptionType` field. The Cloud Function RTDN handler performs the
 * same canonicalisation on the server side.
 *
 * Play Console configuration (must match exactly):
 *  - Subscription `premium_monthly`  → base plan `monthly`,  offer `freetrial` (P7D)
 *  - Subscription `premium_annually` → base plan `annually`, offer `freetrial` (P7D)
 *  - In-app product `premium_lifetime` (managed product / non-consumable)
 */
object BillingProducts {

    /** Auto-renewing monthly subscription. */
    const val MONTHLY: String = "premium_monthly"

    /** Auto-renewing annual subscription. */
    const val ANNUALLY: String = "premium_annually"

    /** Non-consumable lifetime unlock. */
    const val LIFETIME: String = "premium_lifetime"

    /** Every subscription product ID — used by [com.android.billingclient.api.QueryProductDetailsParams]. */
    val SUBSCRIPTION_IDS: List<String> = listOf(MONTHLY, ANNUALLY)

    /** Every one-time (INAPP) product ID. */
    val ONE_TIME_IDS: List<String> = listOf(LIFETIME)

    /** Every product the paywall surfaces. */
    val ALL_IDS: List<String> = SUBSCRIPTION_IDS + ONE_TIME_IDS

    /** Convert a Play product ID into the canonical tier written to Firestore. */
    fun toCanonicalTier(productId: String): SubscriptionType = when (productId) {
        MONTHLY -> SubscriptionType.Monthly
        ANNUALLY -> SubscriptionType.Yearly
        LIFETIME -> SubscriptionType.Lifetime
        else -> SubscriptionType.None
    }
}
