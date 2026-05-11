package com.budgetella.app.data.repository

import com.budgetella.app.data.local.dao.CategoryDao
import com.budgetella.app.data.local.dao.TransactionDao
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.remote.FirestoreService
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Read/write access to transactions. Source-of-truth is Firestore once sync
 * lands in M3; for now this is a thin wrapper over Room with `pushRemote`
 * stubbed out so the call sites already exist when sync goes online.
 */
interface TransactionRepository {
    fun observeAll(userId: String): Flow<List<TransactionEntity>>
    fun observeByType(userId: String, type: TransactionType): Flow<List<TransactionEntity>>
    fun observeMonthRange(userId: String, startMillis: Long, endMillis: Long): Flow<List<TransactionEntity>>

    suspend fun get(id: String): TransactionEntity?
    suspend fun listMonthRange(userId: String, startMillis: Long, endMillis: Long): List<TransactionEntity>

    suspend fun upsert(transaction: TransactionEntity)
    suspend fun delete(id: String)
    suspend fun wipeForUser(userId: String)
}

@Singleton
class RoomTransactionRepository @Inject constructor(
    private val dao: TransactionDao,
    private val categoryDao: CategoryDao,
    private val firestore: FirestoreService,
) : TransactionRepository {

    override fun observeAll(userId: String): Flow<List<TransactionEntity>> =
        dao.observeByUser(userId)

    override fun observeByType(userId: String, type: TransactionType): Flow<List<TransactionEntity>> =
        dao.observeByUserAndType(userId, type.raw)

    override fun observeMonthRange(
        userId: String,
        startMillis: Long,
        endMillis: Long
    ): Flow<List<TransactionEntity>> =
        dao.observeRange(userId, startMillis, endMillis)

    override suspend fun get(id: String): TransactionEntity? = dao.findById(id)

    override suspend fun listMonthRange(
        userId: String,
        startMillis: Long,
        endMillis: Long
    ): List<TransactionEntity> = dao.listRange(userId, startMillis, endMillis)

    override suspend fun upsert(transaction: TransactionEntity) {
        dao.upsert(transaction)
        // Push to Firestore best-effort — offline edits live in Room until the
        // next successful network call carries them up. Don't crash the UI if
        // the network is down or rules reject the write.
        runCatching {
            val slug = transaction.categoryId?.let { categoryDao.findById(it)?.slug }
            // Skip Firestore push for the local placeholder user — it has no Firestore doc.
            if (transaction.userId.isNotEmpty() && transaction.userId != LOCAL_USER_ID) {
                firestore.uploadTransaction(transaction, slug)
            }
        }
    }

    override suspend fun delete(id: String) {
        val row = dao.findById(id)
        dao.deleteById(id)
        runCatching {
            if (row != null && row.userId.isNotEmpty() && row.userId != LOCAL_USER_ID) {
                firestore.deleteTransaction(id, row.userId)
            }
        }
    }

    override suspend fun wipeForUser(userId: String) {
        dao.deleteAllForUser(userId)
    }

    companion object {
        private const val LOCAL_USER_ID = "local"
    }
}
