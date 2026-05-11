package com.budgetella.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.budgetella.app.data.local.entity.TransactionEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface TransactionDao {

    /** Active user's transactions, newest first — replaces SwiftData @Query reverse-by-date. */
    @Query("SELECT * FROM transactions WHERE userId = :userId ORDER BY date DESC")
    fun observeByUser(userId: String): Flow<List<TransactionEntity>>

    /** Filtered by type — used by the Income/Expense pill in TransactionsView. */
    @Query("SELECT * FROM transactions WHERE userId = :userId AND type = :typeRaw ORDER BY date DESC")
    fun observeByUserAndType(userId: String, typeRaw: String): Flow<List<TransactionEntity>>

    /** Single transaction — for the edit sheet. */
    @Query("SELECT * FROM transactions WHERE id = :id LIMIT 1")
    suspend fun findById(id: String): TransactionEntity?

    /** Month range — used by Stats + Budgi insights. Inclusive start, exclusive end. */
    @Query(
        "SELECT * FROM transactions " +
        "WHERE userId = :userId AND date >= :startMillis AND date < :endMillis " +
        "ORDER BY date DESC"
    )
    fun observeRange(userId: String, startMillis: Long, endMillis: Long): Flow<List<TransactionEntity>>

    /** Suspending range fetch (one-shot) for compute-heavy callers like the AI insight engine. */
    @Query(
        "SELECT * FROM transactions " +
        "WHERE userId = :userId AND date >= :startMillis AND date < :endMillis"
    )
    suspend fun listRange(userId: String, startMillis: Long, endMillis: Long): List<TransactionEntity>

    /** All rows for a user — used by the Firestore listener to reconcile deletes. */
    @Query("SELECT * FROM transactions WHERE userId = :userId")
    suspend fun listForUser(userId: String): List<TransactionEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(transaction: TransactionEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(transactions: List<TransactionEntity>)

    @Query("DELETE FROM transactions WHERE id = :id")
    suspend fun deleteById(id: String): Int

    /** Wipe all rows for a user — used at sign-out and during destructive sync. */
    @Query("DELETE FROM transactions WHERE userId = :userId")
    suspend fun deleteAllForUser(userId: String): Int

    @Query("SELECT COUNT(*) FROM transactions WHERE userId = :userId")
    suspend fun countForUser(userId: String): Int
}
