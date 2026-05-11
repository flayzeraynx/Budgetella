package com.budgetella.app.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.data.prefs.NotificationPrefs
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/** Thin facade so the sheet writes via Hilt-owned coroutine scope. */
@HiltViewModel
class NotificationSettingsViewModel @Inject constructor(
    private val prefs: NotificationPrefs,
) : ViewModel() {

    val state: StateFlow<NotificationPrefs.State> = prefs.state
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), NotificationPrefs.State())

    fun setAllEnabled(value: Boolean) = viewModelScope.launch { prefs.setAllEnabled(value) }
    fun setWeeklyDigest(value: Boolean) = viewModelScope.launch { prefs.setWeeklyDigest(value) }
    fun setAnomalyAlerts(value: Boolean) = viewModelScope.launch { prefs.setAnomalyAlerts(value) }
    fun setSavingsSuggestions(value: Boolean) = viewModelScope.launch { prefs.setSavingsSuggestions(value) }
}
