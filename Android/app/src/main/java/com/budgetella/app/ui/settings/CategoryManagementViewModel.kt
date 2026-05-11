package com.budgetella.app.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.CategoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
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
 * Drives [CategoryManagementSheet]. Pulls all categories for the active user
 * and exposes simple rename / delete / add operations. Defaults can be
 * renamed and deleted just like custom ones — the seed flag is purely
 * informational.
 */
@HiltViewModel
class CategoryManagementViewModel @Inject constructor(
    private val categoryRepository: CategoryRepository,
    private val userPrefs: UserPrefs,
) : ViewModel() {

    @OptIn(ExperimentalCoroutinesApi::class)
    val state: StateFlow<CategoryManagementState> = userPrefs.currentUserId
        .flatMapLatest { uid -> categoryRepository.observeAll(uid) }
        .map { cats ->
            CategoryManagementState(
                income = cats.filter { it.type == TransactionType.Income }
                    .sortedBy { it.sortOrder },
                expense = cats.filter { it.type == TransactionType.Expense }
                    .sortedBy { it.sortOrder },
            )
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), CategoryManagementState())

    fun rename(category: CategoryEntity, newName: String) {
        val cleaned = newName.trim()
        if (cleaned.isBlank() || cleaned == category.name) return
        viewModelScope.launch {
            categoryRepository.upsert(category.copy(name = cleaned))
        }
    }

    fun delete(category: CategoryEntity) {
        viewModelScope.launch {
            categoryRepository.delete(category.id)
        }
    }

    fun add(name: String, type: TransactionType, colorHex: String, iconName: String) {
        val cleaned = name.trim()
        if (cleaned.isBlank()) return
        viewModelScope.launch {
            val uid = userPrefs.currentUserId.first()
            val nextSort = (state.value.income + state.value.expense)
                .maxOfOrNull { it.sortOrder } ?: 0
            val entity = CategoryEntity(
                id = UUID.randomUUID().toString(),
                userId = uid,
                name = cleaned,
                slug = null,                       // user-created categories carry no slug
                typeRaw = type.raw,
                iconName = iconName,
                colorHex = colorHex,
                isDefault = false,
                sortOrder = nextSort + 1,
                createdAt = System.currentTimeMillis(),
            )
            categoryRepository.upsert(entity)
        }
    }
}
