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
import kotlinx.coroutines.flow.flatMapLatest
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

    @OptIn(ExperimentalCoroutinesApi::class)
    val isPremium: StateFlow<Boolean> = userPrefs.currentUserId
        .flatMapLatest { uid -> subscriptionRepository.observeIsPremium(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

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
            val details = products.value.firstOrNull { it.productId == plan.productId }
            val offerToken = details
                ?.subscriptionOfferDetails
                ?.firstOrNull()
                ?.offerToken
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
                details.subscriptionOfferDetails
                    ?.firstOrNull()
                    ?.pricingPhases
                    ?.pricingPhaseList
                    ?.lastOrNull()
                    ?.formattedPrice
            }
            PaywallPlan.Lifetime -> details.oneTimePurchaseOfferDetails?.formattedPrice
        }
    }
}
