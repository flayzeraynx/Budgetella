package com.budgetella.app.data.repository

import com.budgetella.app.data.local.dao.NotificationRecordDao
import com.budgetella.app.data.local.entity.NotificationRecordEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

interface NotificationRepository {
    fun observeAll(userId: String): Flow<List<NotificationRecordEntity>>
    fun observeUnreadCount(userId: String): Flow<Int>
    suspend fun record(record: NotificationRecordEntity)
    suspend fun markRead(id: String)
    suspend fun markAllRead(userId: String)
    suspend fun clear(userId: String)
}

@Singleton
class RoomNotificationRepository @Inject constructor(
    private val dao: NotificationRecordDao,
) : NotificationRepository {
    override fun observeAll(userId: String): Flow<List<NotificationRecordEntity>> = dao.observeByUser(userId)
    override fun observeUnreadCount(userId: String): Flow<Int> = dao.observeUnreadCount(userId)
    override suspend fun record(record: NotificationRecordEntity) = dao.upsert(record)
    override suspend fun markRead(id: String) = dao.markRead(id)
    override suspend fun markAllRead(userId: String) = dao.markAllRead(userId)
    override suspend fun clear(userId: String) = dao.deleteAllForUser(userId)
}
