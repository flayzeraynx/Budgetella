package com.budgetella.app.ui.notifications

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.data.local.entity.NotificationRecordEntity
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.repository.NotificationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NotificationInboxState(
    val items: List<NotificationRecordEntity> = emptyList(),
    val unreadCount: Int = 0,
) {
    val isEmpty: Boolean get() = items.isEmpty()
    val hasUnread: Boolean get() = unreadCount > 0
}

@HiltViewModel
class NotificationInboxViewModel @Inject constructor(
    private val userPrefs: UserPrefs,
    private val notifications: NotificationRepository,
) : ViewModel() {

    @OptIn(ExperimentalCoroutinesApi::class)
    val state: StateFlow<NotificationInboxState> = userPrefs.currentUserId
        .flatMapLatest { uid ->
            kotlinx.coroutines.flow.combine(
                notifications.observeAll(uid),
                notifications.observeUnreadCount(uid),
            ) { items, unread -> NotificationInboxState(items, unread) }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), NotificationInboxState())

    fun markRead(id: String) {
        viewModelScope.launch { notifications.markRead(id) }
    }

    fun markAllRead() {
        viewModelScope.launch {
            val uid = userPrefs.currentUserId.first()
            notifications.markAllRead(uid)
        }
    }

    fun clear() {
        viewModelScope.launch {
            val uid = userPrefs.currentUserId.first()
            notifications.clear(uid)
        }
    }
}
