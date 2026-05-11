package com.budgetella.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.budgetella.app.data.local.entity.CategoryEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CategoryDao {

    @Query("SELECT * FROM categories WHERE userId = :userId ORDER BY sortOrder ASC")
    fun observeByUser(userId: String): Flow<List<CategoryEntity>>

    /** One-shot snapshot — used during Firestore sync to push current state. */
    @Query("SELECT * FROM categories WHERE userId = :userId ORDER BY sortOrder ASC")
    suspend fun listByUser(userId: String): List<CategoryEntity>

    @Query("SELECT * FROM categories WHERE userId = :userId AND type = :typeRaw ORDER BY sortOrder ASC")
    fun observeByUserAndType(userId: String, typeRaw: String): Flow<List<CategoryEntity>>

    @Query("SELECT * FROM categories WHERE id = :id LIMIT 1")
    suspend fun findById(id: String): CategoryEntity?

    @Query("SELECT * FROM categories WHERE userId = :userId AND slug = :slug ORDER BY sortOrder ASC LIMIT 1")
    suspend fun findBySlug(userId: String, slug: String): CategoryEntity?

    @Query("SELECT COUNT(*) FROM categories WHERE userId = :userId")
    suspend fun countForUser(userId: String): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(category: CategoryEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(categories: List<CategoryEntity>)

    @Query("DELETE FROM categories WHERE id = :id")
    suspend fun deleteById(id: String): Int

    @Query("DELETE FROM categories WHERE userId = :userId")
    suspend fun deleteAllForUser(userId: String): Int
}
