package com.budgetella.app.di

import com.budgetella.app.data.auth.AuthRepository
import com.budgetella.app.data.auth.FirebaseAuthRepository
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.ktx.auth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Auth + Firebase singletons. Kept separate from the data-layer module so the
 * Firebase plugin remains opt-in (DataModule has no Firebase dependency, so
 * the data layer compiles even before google-services.json is dropped in).
 */
@Module
@InstallIn(SingletonComponent::class)
object FirebaseModule {
    @Provides
    @Singleton
    fun provideFirebaseAuth(): FirebaseAuth = Firebase.auth

    @Provides
    @Singleton
    fun provideFirestore(): FirebaseFirestore = Firebase.firestore
}

@Module
@InstallIn(SingletonComponent::class)
abstract class AuthModule {
    @Binds @Singleton
    abstract fun bindAuthRepository(impl: FirebaseAuthRepository): AuthRepository
}
