package com.budgetella.app.data.repository

import com.budgetella.app.data.local.dao.UserDao
import com.budgetella.app.data.local.entity.UserEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

interface UserRepository {
    fun observeUser(uid: String): Flow<UserEntity?>
    suspend fun getUser(uid: String): UserEntity?
    suspend fun upsert(user: UserEntity)
    suspend fun deleteUser(uid: String)
    suspend fun signOutLocal()
}

@Singleton
class RoomUserRepository @Inject constructor(
    private val dao: UserDao,
) : UserRepository {

    override fun observeUser(uid: String): Flow<UserEntity?> = dao.observeByUid(uid)

    override suspend fun getUser(uid: String): UserEntity? = dao.findByUid(uid)

    override suspend fun upsert(user: UserEntity) {
        dao.upsert(user)
        // TODO(M3): mirror profile patch to Firestore users/{uid}
    }

    override suspend fun deleteUser(uid: String) {
        dao.deleteByUid(uid)
    }

    /** Wipe the cached user row at sign-out. Auth + Firestore are signed out elsewhere. */
    override suspend fun signOutLocal() {
        dao.deleteAll()
    }
}
