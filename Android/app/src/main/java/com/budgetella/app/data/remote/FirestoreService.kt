package com.budgetella.app.data.remote

import com.budgetella.app.data.local.dao.CategoryDao
import com.budgetella.app.data.local.dao.TransactionDao
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.repository.CategoryRepository
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Cross-platform sync — talks Firestore in the exact schema the iOS app reads
 * and writes (see [FirestoreMappers]). Used by:
 *   - Repository upserts → push to Firestore after Room write (best effort)
 *   - Repository deletes → mirror on Firestore
 *   - Auth post-sign-in flow → [fetchAndSync] to pull existing data
 *
 * No real-time snapshot listeners yet — the app reads from Room, and Room is
 * kept fresh by pull-on-sign-in plus write-through on every edit. Live
 * snapshot streaming lands in a follow-up so we can ship M3 without taking
 * on the merge-conflict complexity here.
 */
@Singleton
class FirestoreService @Inject constructor(
    private val firestore: FirebaseFirestore,
    private val transactionDao: TransactionDao,
    private val categoryDao: CategoryDao,
    private val categoryRepository: CategoryRepository,
) {

    private fun userDoc(uid: String) = firestore.collection("users").document(uid)
    private fun transactionsCol(uid: String) = userDoc(uid).collection("transactions")
    private fun categoriesCol(uid: String) = userDoc(uid).collection("categories")

    // ── Push ───────────────────────────────────────────────────────────────

    /**
     * Push a single transaction. Caller resolves the category slug — the Room
     * FK is by id but Firestore stores the slug for cross-device portability.
     */
    suspend fun uploadTransaction(entity: TransactionEntity, categorySlug: String?) {
        transactionsCol(entity.userId)
            .document(entity.id)
            .set(FirestoreMappers.transactionToDoc(entity, categorySlug), SetOptions.merge())
            .await()
    }

    suspend fun deleteTransaction(id: String, userId: String) {
        transactionsCol(userId).document(id).delete().await()
    }

    suspend fun uploadCategory(entity: CategoryEntity) {
        categoriesCol(entity.userId)
            .document(entity.id)
            .set(FirestoreMappers.categoryToDoc(entity), SetOptions.merge())
            .await()
    }

    suspend fun deleteCategory(id: String, userId: String) {
        categoriesCol(userId).document(id).delete().await()
    }

    // ── Initial pull on sign-in ────────────────────────────────────────────

    /**
     * Mirror of iOS FirestoreService.fetchAndSync. On first sign-in:
     *   - If Firestore is empty for this uid, seed defaults locally + push them up.
     *   - Otherwise wipe local rows for this uid and replace with the Firestore
     *     set, re-linking transactions to categories by slug.
     *
     * Errors are propagated so the caller (post-sign-in flow) can decide
     * whether to retry; the typical answer is "no, the user can continue
     * offline and sync will catch up on the next write".
     */
    suspend fun fetchAndSync(userId: String) {
        val categoriesSnapshot = categoriesCol(userId).get().await()
        val remoteCategories = categoriesSnapshot.documents.mapNotNull { doc ->
            doc.data?.let { FirestoreMappers.docToCategory(it) }
        }

        if (remoteCategories.isEmpty()) {
            // New account on the cloud — seed locally + push the defaults up.
            categoryRepository.seedDefaultsIfNeeded(userId)
            val seeded = categoryDao.listByUser(userId)
            seeded.forEach { runCatching { uploadCategory(it) } }
            return
        }

        // Returning user — replace local for this uid.
        transactionDao.deleteAllForUser(userId)
        categoryDao.deleteAllForUser(userId)
        categoryDao.upsertAll(remoteCategories)

        val transactionsSnapshot = transactionsCol(userId).get().await()
        val slugToCategoryId: Map<String, String> = remoteCategories
            .mapNotNull { it.slug?.let { slug -> slug to it.id } }
            .toMap()

        val remoteTransactions = transactionsSnapshot.documents.mapNotNull { doc ->
            doc.data?.let { FirestoreMappers.docToTransaction(it, slugToCategoryId) }
        }
        if (remoteTransactions.isNotEmpty()) {
            transactionDao.upsertAll(remoteTransactions)
        }
    }
}
