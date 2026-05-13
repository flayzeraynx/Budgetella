package com.budgetella.app.di

import com.budgetella.app.data.billing.PlayBillingSubscriptionRepository
import com.budgetella.app.data.repository.SubscriptionRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Binds [SubscriptionRepository] to the live Play Billing implementation.
 *
 * The repo is `@Singleton` because [com.android.billingclient.api.BillingClient]
 * is process-scoped — opening more than one client per app produces undefined
 * behaviour. [com.budgetella.app.data.repository.StubSubscriptionRepository]
 * is left in the codebase for unit tests and Compose previews; flip the bind
 * in a debug variant if you want to exercise the paywall without a real
 * Play account.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class SubscriptionModule {

    @Binds
    @Singleton
    abstract fun bindSubscriptionRepository(
        impl: PlayBillingSubscriptionRepository
    ): SubscriptionRepository
}
