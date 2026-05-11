package com.budgetella.app.data.repository

import com.budgetella.app.data.local.dao.GoalDao
import com.budgetella.app.data.local.entity.GoalEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

interface GoalRepository {
    fun observeActive(userId: String): Flow<List<GoalEntity>>
    fun observeAll(userId: String): Flow<List<GoalEntity>>

    suspend fun get(id: String): GoalEntity?
    suspend fun upsert(goal: GoalEntity)
    suspend fun delete(id: String)
}

@Singleton
class RoomGoalRepository @Inject constructor(
    private val dao: GoalDao,
) : GoalRepository {

    override fun observeActive(userId: String): Flow<List<GoalEntity>> = dao.observeActive(userId)
    override fun observeAll(userId: String): Flow<List<GoalEntity>> = dao.observeAll(userId)
    override suspend fun get(id: String): GoalEntity? = dao.findById(id)

    override suspend fun upsert(goal: GoalEntity) {
        dao.upsert(goal)
        // TODO(M3): mirror to Firestore goals/{userId}/{id}
    }

    override suspend fun delete(id: String) = run { dao.deleteById(id); Unit }
}
