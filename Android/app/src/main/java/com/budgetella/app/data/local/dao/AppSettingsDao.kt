package com.budgetella.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.budgetella.app.data.local.entity.AppSettingsEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AppSettingsDao {

    @Query("SELECT * FROM app_settings WHERE userId = :userId LIMIT 1")
    fun observeForUser(userId: String): Flow<AppSettingsEntity?>

    @Query("SELECT * FROM app_settings WHERE userId = :userId LIMIT 1")
    suspend fun findForUser(userId: String): AppSettingsEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(settings: AppSettingsEntity)

    @Query("DELETE FROM app_settings WHERE userId = :userId")
    suspend fun deleteForUser(userId: String): Int
}
