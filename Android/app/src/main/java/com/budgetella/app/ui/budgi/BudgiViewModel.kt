package com.budgetella.app.ui.budgi

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.locale.LocaleHelper
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.Money
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.data.prefs.UserPrefs
import com.budgetella.app.data.remote.GeminiChatService
import com.budgetella.app.data.repository.CategoryRepository
import com.budgetella.app.data.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.YearMonth
import java.time.ZoneId
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

// ── Chat message data class ───────────────────────────────────────────────

data class BudgiMessage(
    val id: String = UUID.randomUUID().toString(),
    val role: Role,
    val text: String,
    val tag: String? = null,
    val accent: Color = BrandColor.Primary,
) {
    enum class Role { User, Assistant }
}

// ── DataStore wrapper for the AI-data consent flag ─────────────────────────

private val Context.budgiPrefs by preferencesDataStore(name = "budgi_prefs")

@Singleton
class BudgiPrefs @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val key: Preferences.Key<Boolean> = booleanPreferencesKey("aiDataConsentGiven")

    val consentGiven: Flow<Boolean> = context.budgiPrefs.data.map { it[key] ?: false }

    suspend fun setConsent(value: Boolean) {
        context.budgiPrefs.edit { it[key] = value }
    }
}

// ── ViewModel ──────────────────────────────────────────────────────────────

@HiltViewModel
class BudgiViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    transactionRepository: TransactionRepository,
    categoryRepository: CategoryRepository,
    private val chatService: GeminiChatService,
    private val budgiPrefs: BudgiPrefs,
    userPrefs: UserPrefs,
) : ViewModel() {

    @OptIn(ExperimentalCoroutinesApi::class)
    private val transactions: StateFlow<List<TransactionEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> transactionRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    @OptIn(ExperimentalCoroutinesApi::class)
    private val categories: StateFlow<List<CategoryEntity>> = userPrefs.currentUserId
        .flatMapLatest { uid -> categoryRepository.observeAll(uid) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _messages = MutableStateFlow<List<BudgiMessage>>(emptyList())
    val messages: StateFlow<List<BudgiMessage>> = _messages.asStateFlow()

    private val _isSending = MutableStateFlow(false)
    val isSending: StateFlow<Boolean> = _isSending.asStateFlow()

    private val _composer = MutableStateFlow("")
    val composer: StateFlow<String> = _composer.asStateFlow()

    val consentGiven: StateFlow<Boolean> = budgiPrefs.consentGiven
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    private var seeded = false

    /** Prime the conversation with greeting + rule-based insights on first open. */
    fun seedIfNeeded(displayName: String?) {
        if (seeded) return
        viewModelScope.launch {
            // Wait for the first emission of both flows so insights run against
            // real data, not the empty `initialValue`. `.first()` triggers the
            // upstream subscription that WhileSubscribed needs.
            val txs = transactions.first()
            val cats = categories.first()
            val language = LocaleHelper.currentLanguage(context).tag
            val isEn = language.startsWith("en")
            val greeting = greeting(displayName, isEn)
            val intro = if (txs.isEmpty()) {
                if (isEn) "Add a few transactions and I'll start surfacing personalised tips here."
                else "Birkaç işlem ekledikten sonra kişisel öneriler burada belirmeye başlar."
            } else {
                if (isEn) "Here's what I noticed this week:" else "Bu hafta şunları fark ettim:"
            }

            val initial = mutableListOf(
                BudgiMessage(role = BudgiMessage.Role.Assistant, text = "$greeting $intro")
            )
            BudgiInsightEngine.compute(txs, cats, language).forEach { insight ->
                initial += BudgiMessage(
                    role = BudgiMessage.Role.Assistant,
                    text = insight.text,
                    tag = insight.tag,
                    accent = insight.color(),
                )
            }
            _messages.value = initial
            seeded = true
        }
    }

    fun setComposer(value: String) {
        _composer.value = value
    }

    fun setConsent(value: Boolean) {
        viewModelScope.launch { budgiPrefs.setConsent(value) }
    }

    /** Sends the current composer text. Returns true if the call kicked off. */
    fun send() {
        val text = _composer.value.trim()
        if (text.isEmpty() || _isSending.value) return
        _composer.value = ""
        _messages.update { it + BudgiMessage(role = BudgiMessage.Role.User, text = text) }
        _isSending.value = true

        viewModelScope.launch {
            val ctx = buildContextBlock()
            val language = LocaleHelper.currentLanguage(context).tag
            val reply = chatService.send(message = text, contextBlock = ctx, languageCode = language)
            _messages.update { it + BudgiMessage(role = BudgiMessage.Role.Assistant, text = reply) }
            _isSending.value = false
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private fun greeting(displayName: String?, isEn: Boolean): String {
        val name = (displayName?.substringBefore(' ').takeUnless { it.isNullOrBlank() }) ?: "there"
        val hour = java.time.LocalTime.now().hour
        return when {
            hour in 5..11 -> if (isEn) "Good morning $name ☀️" else "Günaydın $name ☀️"
            hour in 12..17 -> if (isEn) "Good afternoon $name 👋" else "İyi günler $name 👋"
            hour in 18..22 -> if (isEn) "Good evening $name 🌙" else "İyi akşamlar $name 🌙"
            else -> if (isEn) "Hi $name 🌙" else "Merhaba $name 🌙"
        }
    }

    private suspend fun buildContextBlock(): String {
        val zone = ZoneId.systemDefault()
        val month = YearMonth.now(zone)
        val monthStart = month.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val nextMonth = month.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val txs = transactions.first()
        val monthTxs = txs.filter { it.date in monthStart until nextMonth }

        val income = monthTxs.filter { it.type == TransactionType.Income }.sumOf { it.amount }
        val expense = monthTxs.filter { it.type == TransactionType.Expense }.sumOf { it.amount }
        val net = income - expense

        val byCat = monthTxs
            .filter { it.type == TransactionType.Expense && it.categoryId != null }
            .groupBy { it.categoryId!! }
            .mapValues { it.value.sumOf { tx -> tx.amount } }
            .entries
            .sortedByDescending { it.value }
            .take(5)
        val cats = categories.first().associateBy { it.id }
        val catLines = byCat.joinToString("\n") { (id, amount) ->
            val name = cats[id]?.name ?: "Other"
            "- $name: ${money(amount)}"
        }
        return """
            User's finances this month:
            - Total income: ${money(income)}
            - Total expense: ${money(expense)}
            - Net: ${money(net)}
            Top expense categories:
            ${catLines.ifBlank { "- no data yet" }}
            Total transactions: ${txs.size}
        """.trimIndent()
    }

    private fun money(minor: Long): String = "₺" + "%,.2f".format(Money(minor).toBigDecimal())
}
