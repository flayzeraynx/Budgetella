package com.budgetella.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.budgetella.app.data.local.entity.NotificationRecordEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface NotificationRecordDao {

    @Query("SELECT * FROM notification_records WHERE userId = :userId ORDER BY createdAt DESC")
    fun observeByUser(userId: String): Flow<List<NotificationRecordEntity>>

    @Query("SELECT COUNT(*) FROM notification_records WHERE userId = :userId AND isRead = 0")
    fun observeUnreadCount(userId: String): Flow<Int>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(record: NotificationRecordEntity)

    @Query("UPDATE notification_records SET isRead = 1 WHERE id = :id")
    suspend fun markRead(id: String)

    @Query("UPDATE notification_records SET isRead = 1 WHERE userId = :userId")
    suspend fun markAllRead(userId: String)

    @Query("DELETE FROM notification_records WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM notification_records WHERE userId = :userId")
    suspend fun deleteAllForUser(userId: String)
}
