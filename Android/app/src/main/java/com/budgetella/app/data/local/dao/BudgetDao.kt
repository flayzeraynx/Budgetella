package com.budgetella.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.budgetella.app.data.local.entity.BudgetEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BudgetDao {

    @Query("SELECT * FROM budgets WHERE userId = :userId AND year = :year AND month = :month")
    fun observeForMonth(userId: String, year: Int, month: Int): Flow<List<BudgetEntity>>

    @Query("SELECT * FROM budgets WHERE userId = :userId ORDER BY year DESC, month DESC")
    fun observeByUser(userId: String): Flow<List<BudgetEntity>>

    @Query("SELECT * FROM budgets WHERE id = :id LIMIT 1")
    suspend fun findById(id: String): BudgetEntity?

    @Query(
        "SELECT * FROM budgets " +
        "WHERE userId = :userId AND categorySlug = :slug AND year = :year AND month = :month " +
        "LIMIT 1"
    )
    suspend fun findExisting(userId: String, slug: String, year: Int, month: Int): BudgetEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(budget: BudgetEntity)

    @Query("DELETE FROM budgets WHERE id = :id")
    suspend fun deleteById(id: String): Int

    @Query("DELETE FROM budgets WHERE userId = :userId")
    suspend fun deleteAllForUser(userId: String): Int
}
