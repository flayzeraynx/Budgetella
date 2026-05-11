package com.budgetella.app.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.BuildConfig
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.CategoryRepository
import com.budgetella.app.data.repository.SubscriptionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

data class CategoryManagementState(
    val income: List<CategoryEntity> = emptyList(),
    val expense: List<CategoryEntity> = emptyList(),
)

/**
 * Drives [CategoryManagementSheet].
 *
 * Default categories (isDefault = true) are read-only — rename and delete
 * calls are silently ignored as a safeguard against corrupting the seeded set.
 * This mirrors iOS CategoryManagementView which hides swipe-actions on default rows.
 *
 * New category creation is gated behind premium. In DEBUG builds the check
 * is always bypassed so the feature remains accessible during development.
 */
@HiltViewModel
class CategoryManagementViewModel @Inject constructor(
    private val categoryRepository: CategoryRepository,
    private val subscriptionRepository: SubscriptionRepository,
    private val userPrefs: UserPrefs,
) : ViewModel() {

    @OptIn(ExperimentalCoroutinesApi::class)
    val state: StateFlow<CategoryManagementState> = userPrefs.currentUserId
        .flatMapLatest { uid -> categoryRepository.observeAll(uid) }
        .map { cats ->
            CategoryManagementState(
                income  = cats.filter { it.type == TransactionType.Income  }.sortedBy { it.sortOrder },
                expense = cats.filter { it.type == TransactionType.Expense }.sortedBy { it.sortOrder },
            )
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), CategoryManagementState())

    /**
     * True when the active user has an active subscription.
     * DEBUG builds are always treated as premium so Add can be tested without
     * a real Play Billing transaction (same as iOS devPremiumUIDs bypass).
     */
    @OptIn(ExperimentalCoroutinesApi::class)
    val isPremium: StateFlow<Boolean> = if (BuildConfig.DEBUG) {
        flowOf(true).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)
    } else {
        userPrefs.currentUserId
            .flatMapLatest { uid -> subscriptionRepository.observeIsPremium(uid) }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)
    }

    /** Rename a category. No-op for default (system) categories. */
    fun rename(category: CategoryEntity, newName: String) {
        // Guard on both isDefault flag AND slug presence — slug is the authoritative
        // indicator even if isDefault was somehow corrupted by a legacy sync.
        if (category.isDefault || category.slug != null) return
        val cleaned = newName.trim()
        if (cleaned.isBlank() || cleaned == category.name) return
        viewModelScope.launch { categoryRepository.upsert(category.copy(name = cleaned)) }
    }

    /** Delete a category. No-op for default (system) categories. */
    fun delete(category: CategoryEntity) {
        if (category.isDefault || category.slug != null) return
        viewModelScope.launch { categoryRepository.delete(category.id) }
    }

    fun add(name: String, type: TransactionType, colorHex: String, iconName: String) {
        val cleaned = name.trim()
        if (cleaned.isBlank()) return
        viewModelScope.launch {
            val uid      = userPrefs.currentUserId.first()
            val nextSort = (state.value.income + state.value.expense).maxOfOrNull { it.sortOrder } ?: 0
            categoryRepository.upsert(
                CategoryEntity(
                    id         = UUID.randomUUID().toString(),
                    userId     = uid,
                    name       = cleaned,
                    slug       = null,        // user-created categories carry no slug
                    typeRaw    = type.raw,
                    iconName   = iconName,
                    colorHex   = colorHex,
                    isDefault  = false,
                    sortOrder  = nextSort + 1,
                    createdAt  = System.currentTimeMillis(),
                )
            )
        }
    }
}
