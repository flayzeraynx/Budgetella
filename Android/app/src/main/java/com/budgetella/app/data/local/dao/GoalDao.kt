package com.budgetella.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.budgetella.app.data.local.entity.GoalEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface GoalDao {

    @Query("SELECT * FROM goals WHERE userId = :userId AND isArchived = 0 ORDER BY createdAt DESC")
    fun observeActive(userId: String): Flow<List<GoalEntity>>

    @Query("SELECT * FROM goals WHERE userId = :userId ORDER BY createdAt DESC")
    fun observeAll(userId: String): Flow<List<GoalEntity>>

    @Query("SELECT * FROM goals WHERE id = :id LIMIT 1")
    suspend fun findById(id: String): GoalEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(goal: GoalEntity)

    @Query("DELETE FROM goals WHERE id = :id")
    suspend fun deleteById(id: String): Int

    @Query("DELETE FROM goals WHERE userId = :userId")
    suspend fun deleteAllForUser(userId: String): Int
}
