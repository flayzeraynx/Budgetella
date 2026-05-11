package com.budgetella.app.di

import com.budgetella.app.data.repository.StubSubscriptionRepository
import com.budgetella.app.data.repository.SubscriptionRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Binds [SubscriptionRepository] to the v1 stub. Swap the binding to a
 * PlayBilling-backed implementation once M8.1 ships — every call site
 * (PaywallScreen, premium feature gates) reads through the interface.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class SubscriptionModule {

    @Binds
    @Singleton
    abstract fun bindSubscriptionRepository(
        impl: StubSubscriptionRepository
    ): SubscriptionRepository
}
