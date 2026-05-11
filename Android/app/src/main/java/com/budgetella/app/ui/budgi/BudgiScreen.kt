package com.budgetella.app.ui.budgi

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing

@Composable
fun BudgiScreen(modifier: Modifier = Modifier) {
    val vm: BudgiViewModel = hiltViewModel()
    val messages by vm.messages.collectAsStateWithLifecycle()
    val isSending by vm.isSending.collectAsStateWithLifecycle()
    val composer by vm.composer.collectAsStateWithLifecycle()
    val consent by vm.consentGiven.collectAsStateWithLifecycle()
    var showConsent by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()

    // Re-seed whenever the locale changes — Activity recreate fires this
     // composable afresh, and the Configuration's language tag triggers a
     // re-fire so the welcome message + rule insights swap to the new locale.
    val context = androidx.compose.ui.platform.LocalContext.current
    val currentLangTag = context.resources.configuration.locales.toLanguageTags().substringBefore(',')
    LaunchedEffect(currentLangTag) { vm.seedIfNeeded(displayName = null) }
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) listState.animateScrollToItem(messages.size - 1)
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BrandColor.background())
            .statusBarsPadding()
    ) {
        Header()

        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            contentPadding = PaddingValues(
                horizontal = Spacing.xl,
                vertical = Spacing.lg
            ),
            verticalArrangement = Arrangement.spacedBy(Spacing.md),
        ) {
            items(messages, key = { it.id }) { msg ->
                MessageBubble(msg)
            }
            if (isSending) item("typing") { TypingIndicator() }
        }

        Composer(
            text = composer,
            onTextChange = vm::setComposer,
            onSend = {
                if (!consent) showConsent = true else vm.send()
            },
            modifier = Modifier.navigationBarsPadding()
        )
    }

    if (showConsent) {
        AlertDialog(
            onDismissRequest = { showConsent = false },
            title = { Text(stringResource(R.string.budgi_consent_title)) },
            text = { Text(stringResource(R.string.budgi_consent_body)) },
            confirmButton = {
                TextButton(onClick = {
                    vm.setConsent(true)
                    showConsent = false
                    vm.send()
                }) { Text(stringResource(R.string.budgi_consent_accept), color = BrandColor.Primary) }
            },
            dismissButton = {
                TextButton(onClick = { showConsent = false }) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
        )
    }
}

// ── Header ────────────────────────────────────────────────────────────────

@Composable
private fun Header() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.xl, vertical = Spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(
                    Brush.linearGradient(listOf(BrandColor.Primary, BrandColor.PrimaryLight))
                ),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.Filled.AutoAwesome,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(22.dp),
            )
        }
        Spacer(Modifier.width(Spacing.sm))
        Column {
            Text(
                text = stringResource(R.string.budgi_title),
                style = BrandText.headline,
                color = BrandColor.textPrimary(),
            )
            Text(
                text = stringResource(R.string.budgi_subtitle),
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
        }
    }
}

// ── Bubble ────────────────────────────────────────────────────────────────

@Composable
private fun MessageBubble(msg: BudgiMessage) {
    when (msg.role) {
        BudgiMessage.Role.User -> Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End,
        ) {
            Text(
                text = msg.text,
                style = BrandText.body,
                color = Color.White,
                modifier = Modifier
                    .widthIn(max = 280.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(BrandColor.Primary)
                    .padding(horizontal = Spacing.md, vertical = Spacing.sm),
            )
        }
        BudgiMessage.Role.Assistant -> AssistantBubble(msg)
    }
}

@Composable
private fun AssistantBubble(msg: BudgiMessage) {
    if (msg.tag != null) {
        Column(
            modifier = Modifier
                .widthIn(max = 320.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(msg.accent.copy(alpha = 0.10f))
                .padding(Spacing.md),
            verticalArrangement = Arrangement.spacedBy(Spacing.xs),
        ) {
            Text(text = msg.tag, style = BrandText.caption, color = msg.accent)
            Text(text = msg.text, style = BrandText.footnote, color = BrandColor.textPrimary())
        }
    } else {
        Text(
            text = msg.text,
            style = BrandText.footnote,
            color = BrandColor.textPrimary(),
            modifier = Modifier
                .widthIn(max = 300.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(BrandColor.surface().copy(alpha = 0.6f))
                .padding(Spacing.md),
        )
    }
}

@Composable
private fun TypingIndicator() {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(BrandColor.surface().copy(alpha = 0.6f))
            .padding(horizontal = Spacing.md, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        repeat(3) { i ->
            val alpha by animateFloatAsState(
                targetValue = 1f,
                animationSpec = tween(durationMillis = 600 + i * 200),
                label = "dot$i",
            )
            Box(
                modifier = Modifier
                    .size(7.dp)
                    .clip(CircleShape)
                    .background(BrandColor.textTertiary().copy(alpha = alpha)),
            )
        }
    }
}

// ── Composer ──────────────────────────────────────────────────────────────

@Composable
private fun Composer(
    text: String,
    onTextChange: (String) -> Unit,
    onSend: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(BrandColor.background())
            .padding(horizontal = Spacing.xl, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(50))
                .background(BrandColor.surface().copy(alpha = 0.5f))
                .border(
                    width = 1.dp,
                    color = BrandColor.borderMedium(),
                    shape = RoundedCornerShape(50),
                )
                .padding(horizontal = Spacing.md, vertical = 10.dp),
        ) {
            if (text.isEmpty()) {
                Text(
                    text = stringResource(R.string.budgi_composer_hint),
                    style = BrandText.body,
                    color = BrandColor.textTertiary(),
                )
            }
            BasicTextField(
                value = text,
                onValueChange = onTextChange,
                textStyle = TextStyle(
                    color = BrandColor.textPrimary(),
                    fontSize = BrandText.body.fontSize,
                ),
                cursorBrush = androidx.compose.ui.graphics.SolidColor(BrandColor.Primary),
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                    capitalization = KeyboardCapitalization.Sentences,
                    imeAction = ImeAction.Send,
                ),
                keyboardActions = androidx.compose.foundation.text.KeyboardActions(
                    onSend = { onSend() }
                ),
                modifier = Modifier.fillMaxWidth(),
            )
        }
        Spacer(Modifier.width(Spacing.sm))
        val enabled = text.trim().isNotEmpty()
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(if (enabled) BrandColor.Primary else BrandColor.surface())
                .clickable(enabled = enabled, onClick = onSend),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.Send,
                contentDescription = stringResource(R.string.budgi_send),
                tint = if (enabled) Color.White else BrandColor.textTertiary(),
                modifier = Modifier.size(20.dp),
            )
        }
    }
}
