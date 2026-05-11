package com.budgetella.app.data.repository

import com.budgetella.app.data.local.dao.CategoryDao
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.model.CategorySlug
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.remote.FirestoreService
import dagger.Lazy
import kotlinx.coroutines.flow.Flow
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

interface CategoryRepository {
    fun observeAll(userId: String): Flow<List<CategoryEntity>>
    fun observeByType(userId: String, type: TransactionType): Flow<List<CategoryEntity>>

    suspend fun get(id: String): CategoryEntity?
    suspend fun findBySlug(userId: String, slug: CategorySlug): CategoryEntity?
    suspend fun count(userId: String): Int

    suspend fun upsert(category: CategoryEntity)
    suspend fun delete(id: String)

    /** Seed the 15 default categories for a brand-new user. No-op if any exist. */
    suspend fun seedDefaultsIfNeeded(userId: String)
}

@Singleton
class RoomCategoryRepository @Inject constructor(
    private val dao: CategoryDao,
    // FirestoreService depends on CategoryRepository (for seedDefaults via its
    // own initial-sync path), so we wrap with `dagger.Lazy` to break the cycle.
    private val firestore: Lazy<FirestoreService>,
) : CategoryRepository {

    override fun observeAll(userId: String): Flow<List<CategoryEntity>> =
        dao.observeByUser(userId)

    override fun observeByType(userId: String, type: TransactionType): Flow<List<CategoryEntity>> =
        dao.observeByUserAndType(userId, type.raw)

    override suspend fun get(id: String): CategoryEntity? = dao.findById(id)

    override suspend fun findBySlug(userId: String, slug: CategorySlug): CategoryEntity? =
        dao.findBySlug(userId, slug.raw)

    override suspend fun count(userId: String): Int = dao.countForUser(userId)

    override suspend fun upsert(category: CategoryEntity) {
        dao.upsert(category)
        runCatching {
            if (category.userId.isNotEmpty() && category.userId != LOCAL_USER_ID) {
                firestore.get().uploadCategory(category)
            }
        }
    }

    override suspend fun delete(id: String) {
        val row = dao.findById(id)
        dao.deleteById(id)
        runCatching {
            if (row != null && row.userId.isNotEmpty() && row.userId != LOCAL_USER_ID) {
                firestore.get().deleteCategory(id, row.userId)
            }
        }
    }

    override suspend fun seedDefaultsIfNeeded(userId: String) {
        if (dao.countForUser(userId) > 0) return
        val now = System.currentTimeMillis()
        val seeds = CategorySlug.entries.mapIndexed { index, slug ->
            CategoryEntity(
                id = UUID.randomUUID().toString(),
                userId = userId,
                name = slug.turkishName,        // matches iOS — display name is i18n'd at render time
                slug = slug.raw,
                typeRaw = slug.type.raw,
                iconName = slug.defaultIcon,
                colorHex = slug.defaultColorHex,
                isDefault = true,
                sortOrder = index,
                createdAt = now,
            )
        }
        dao.upsertAll(seeds)
    }

    companion object {
        private const val LOCAL_USER_ID = "local"
    }
}
