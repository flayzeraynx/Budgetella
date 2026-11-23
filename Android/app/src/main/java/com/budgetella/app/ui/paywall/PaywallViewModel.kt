package com.budgetella.app.ui.paywall

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.android.billingclient.api.ProductDetails
import com.budgetella.app.data.billing.BillingProducts
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.SubscriptionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Paywall plans surfaced to the UI. Order matters — `Yearly` is selected by
 * default to nudge toward the higher-LTV option (same default as iOS).
 */
enum class PaywallPlan(val productId: String) {
    Monthly(BillingProducts.MONTHLY),
    Yearly(BillingProducts.ANNUALLY),
    Lifetime(BillingProducts.LIFETIME),
}

/** UI state for the purchase CTA. */
sealed interface PurchaseState {
    data object Idle : PurchaseState
    data object Loading : PurchaseState
    /** Purchase flow returned; entitlement is now reconciling via Firestore. */
    data object Success : PurchaseState
    data class Error(val message: String) : PurchaseState
}

/**
 * Backs [PaywallScreen]. Owns the selected plan, drives purchases, and
 * exposes [ProductDetails] so the UI can render localized prices straight
 * from Play (USD on US Play accounts, ₺ TRY on Turkish accounts).
 */
@HiltViewModel
class PaywallViewModel @Inject constructor(
    private val subscriptionRepository: SubscriptionRepository,
    private val userPrefs: UserPrefs,
) : ViewModel() {

    val products: StateFlow<List<ProductDetails>> = subscriptionRepository
        .observeProducts()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /**
     * `null` until the first entitlement snapshot arrives. Gates lock only on
     * an explicit `false`, so paying users never see a locked flash or a
     * proactive paywall while Firestore is still answering.
     */
    @OptIn(ExperimentalCoroutinesApi::class)
    val premiumState: StateFlow<Boolean?> = userPrefs.currentUserId
        .flatMapLatest { uid -> subscriptionRepository.observeIsPremium(uid) }
        .map<Boolean, Boolean?> { it }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    val isPremium: StateFlow<Boolean> = premiumState
        .map { it == true }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    /**
     * Proactive paywall that is due right now, if any. MainScaffold only
     * exists once onboarding/auth are done, hence `onboardingDone = true`.
     */
    val duePrompt: StateFlow<PaywallPrompt?> = combine(
        premiumState,
        userPrefs.paywallShownAfterOnboarding,
        userPrefs.savedTxCount,
        userPrefs.paywallShownAfterTenTx,
    ) { premium, shownOnboarding, txCount, shownAt10 ->
        if (premium == null) null
        else PaywallPrompt.next(
            isPremium = premium,
            onboardingDone = true,
            shownOnboarding = shownOnboarding,
            txCount = txCount,
            shownAt10 = shownAt10,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    /** Persist before presenting so a dismissal is final. */
    fun markPromptShown(prompt: PaywallPrompt) {
        viewModelScope.launch {
            when (prompt) {
                PaywallPrompt.AfterOnboarding -> userPrefs.markPaywallShownAfterOnboarding()
                PaywallPrompt.AfterTenthTransaction -> userPrefs.markPaywallShownAfterTenTx()
            }
        }
    }

    private val _selectedPlan = MutableStateFlow(PaywallPlan.Yearly)
    val selectedPlan: StateFlow<PaywallPlan> = _selectedPlan.asStateFlow()

    private val _purchaseState = MutableStateFlow<PurchaseState>(PurchaseState.Idle)
    val purchaseState: StateFlow<PurchaseState> = _purchaseState.asStateFlow()

    fun selectPlan(plan: PaywallPlan) {
        _selectedPlan.value = plan
    }

    /** Launch the Play purchase sheet for the currently selected plan. */
    fun startPurchase(activity: Activity) {
        val plan = _selectedPlan.value
        viewModelScope.launch {
            _purchaseState.value = PurchaseState.Loading
            val offerToken = offerFor(plan)?.offerToken
            val result = subscriptionRepository.startPurchase(
                activity = activity,
                productId = plan.productId,
                offerToken = offerToken,
            )
            _purchaseState.value = result.fold(
                onSuccess = { PurchaseState.Success },
                onFailure = { PurchaseState.Error(it.message ?: "Purchase failed.") }
            )
        }
    }

    fun restorePurchases() {
        viewModelScope.launch {
            _purchaseState.value = PurchaseState.Loading
            val result = subscriptionRepository.restorePurchases()
            _purchaseState.value = result.fold(
                onSuccess = { PurchaseState.Idle },
                onFailure = { PurchaseState.Error(it.message ?: "Restore failed.") }
            )
        }
    }

    fun acknowledgeError() {
        if (_purchaseState.value is PurchaseState.Error) {
            _purchaseState.value = PurchaseState.Idle
        }
    }

    /** Pull the localized price string for [plan] off the cached ProductDetails. */
    fun formattedPrice(plan: PaywallPlan): String? {
        val details = products.value.firstOrNull { it.productId == plan.productId }
            ?: return null
        return when (plan) {
            PaywallPlan.Monthly, PaywallPlan.Yearly -> {
                // Use the trial offer's recurring base-plan phase if present;
                // otherwise fall back to the first phase. The phase ordering
                // is [free trial, recurring], so the last phase is always the
                // real charge price.
                offerFor(plan)
                    ?.pricingPhases
                    ?.pricingPhaseList
                    ?.lastOrNull()
                    ?.formattedPrice
            }
            PaywallPlan.Lifetime -> details.oneTimePurchaseOfferDetails?.formattedPrice
        }
    }

    /**
     * The offer the purchase will actually use. Play only returns offers this
     * account is eligible for, so a free-trial offer in the list means the
     * trial is redeemable — prefer it, otherwise fall back to the base plan.
     * CTA label, fine print and purchase all read from here so they agree.
     */
    private fun offerFor(plan: PaywallPlan): ProductDetails.SubscriptionOfferDetails? {
        val offers = products.value
            .firstOrNull { it.productId == plan.productId }
            ?.subscriptionOfferDetails
            ?: return null
        return offers.firstOrNull { it.hasFreePhase() } ?: offers.firstOrNull()
    }

    private fun ProductDetails.SubscriptionOfferDetails.hasFreePhase(): Boolean =
        pricingPhases.pricingPhaseList.any { it.priceAmountMicros == 0L }

    /** True only when [plan] will be bought with a free-trial offer. */
    fun hasFreeTrial(plan: PaywallPlan): Boolean = offerFor(plan)?.hasFreePhase() == true

    /** Yearly saving vs. 12× monthly from live Play prices; null when unknown or not cheaper. */
    fun yearlyDiscountPercent(): Int? {
        fun micros(plan: PaywallPlan) =
            offerFor(plan)?.pricingPhases?.pricingPhaseList?.lastOrNull()?.priceAmountMicros
        val monthly = micros(PaywallPlan.Monthly) ?: return null
        val yearly = micros(PaywallPlan.Yearly) ?: return null
        if (monthly <= 0L) return null
        val percent = Math.round((1 - yearly.toDouble() / (monthly * 12.0)) * 100).toInt()
        return percent.takeIf { it > 0 }
    }
}
