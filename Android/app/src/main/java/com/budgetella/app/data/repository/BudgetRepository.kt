package com.budgetella.app.data.repository

import com.budgetella.app.data.local.dao.BudgetDao
import com.budgetella.app.data.local.entity.BudgetEntity
import com.budgetella.app.data.model.CategorySlug
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

interface BudgetRepository {
    fun observeForMonth(userId: String, year: Int, month: Int): Flow<List<BudgetEntity>>
    fun observeAll(userId: String): Flow<List<BudgetEntity>>

    suspend fun get(id: String): BudgetEntity?
    /** Returns the existing budget row for (slug, month, year), or null. */
    suspend fun findExisting(userId: String, slug: CategorySlug, year: Int, month: Int): BudgetEntity?

    suspend fun upsert(budget: BudgetEntity)
    suspend fun delete(id: String)
}

@Singleton
class RoomBudgetRepository @Inject constructor(
    private val dao: BudgetDao,
) : BudgetRepository {

    override fun observeForMonth(userId: String, year: Int, month: Int): Flow<List<BudgetEntity>> =
        dao.observeForMonth(userId, year, month)

    override fun observeAll(userId: String): Flow<List<BudgetEntity>> =
        dao.observeByUser(userId)

    override suspend fun get(id: String): BudgetEntity? = dao.findById(id)

    override suspend fun findExisting(
        userId: String,
        slug: CategorySlug,
        year: Int,
        month: Int
    ): BudgetEntity? = dao.findExisting(userId, slug.raw, year, month)

    override suspend fun upsert(budget: BudgetEntity) {
        dao.upsert(budget)
        // TODO(M3): mirror to Firestore budgets/{userId}/{id}
    }

    override suspend fun delete(id: String) = run { dao.deleteById(id); Unit }
}
