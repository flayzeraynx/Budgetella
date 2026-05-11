package com.budgetella.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.budgetella.app.data.local.entity.UserEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {

    @Query("SELECT * FROM users WHERE uid = :uid LIMIT 1")
    fun observeByUid(uid: String): Flow<UserEntity?>

    @Query("SELECT * FROM users WHERE uid = :uid LIMIT 1")
    suspend fun findByUid(uid: String): UserEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(user: UserEntity)

    @Query("DELETE FROM users WHERE uid = :uid")
    suspend fun deleteByUid(uid: String): Int

    @Query("DELETE FROM users")
    suspend fun deleteAll(): Int
}
