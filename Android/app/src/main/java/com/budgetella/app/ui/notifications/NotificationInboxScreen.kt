package com.budgetella.app.ui.notifications

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Celebration
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.local.entity.NotificationKind
import com.budgetella.app.data.local.entity.NotificationRecordEntity
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

/**
 * Notification inbox — port of iOS NotificationInboxView. Listed as a
 * ModalBottomSheet from Settings. Tap a row to mark read; "Mark all" button
 * surfaces in the top bar when there are unread items.
 */
@Composable
fun NotificationInboxScreen(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val vm: NotificationInboxViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BrandColor.background())
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.lg, vertical = Spacing.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = stringResource(R.string.inbox_title),
                style = BrandText.title,
                color = BrandColor.textPrimary(),
                modifier = Modifier.weight(1f),
            )
            if (state.hasUnread) {
                TextButton(onClick = vm::markAllRead) {
                    Text(
                        text = stringResource(R.string.inbox_mark_all),
                        style = BrandText.footnote,
                        color = BrandColor.Primary,
                    )
                }
            }
        }

        if (state.isEmpty) {
            EmptyInbox(modifier = Modifier.weight(1f))
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(
                    start = Spacing.lg,
                    end = Spacing.lg,
                    bottom = Spacing.xxl,
                ),
                verticalArrangement = Arrangement.spacedBy(Spacing.sm),
            ) {
                items(items = state.items, key = { it.id }) { record ->
                    NotificationRow(
                        record = record,
                        onClick = {
                            vm.markRead(record.id)
                            // Caller can act on deepLink later; for now just mark read.
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun NotificationRow(
    record: NotificationRecordEntity,
    onClick: () -> Unit,
) {
    val kind = NotificationKind.fromRaw(record.kindRaw)
    val tint = kind.tint()
    val icon = kind.icon()

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = if (record.isRead) 0.3f else 0.5f))
            .clickable(onClick = onClick)
            .padding(Spacing.md),
        verticalAlignment = Alignment.Top,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(Spacing.radiusSmall))
                .background(tint.copy(alpha = 0.18f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = tint,
                modifier = Modifier.size(20.dp),
            )
        }
        Spacer(Modifier.width(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = record.title,
                style = BrandText.subheadline.copy(
                    fontWeight = if (record.isRead) FontWeight.Medium else FontWeight.SemiBold
                ),
                color = BrandColor.textPrimary(),
            )
            if (record.body.isNotBlank()) {
                Spacer(Modifier.height(2.dp))
                Text(
                    text = record.body,
                    style = BrandText.footnote,
                    color = BrandColor.textSecondary(),
                )
            }
            Spacer(Modifier.height(4.dp))
            Text(
                text = relativeTime(record.createdAt),
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
        }
        if (!record.isRead) {
            Spacer(Modifier.width(Spacing.sm))
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(RoundedCornerShape(50))
                    .background(BrandColor.Primary)
            )
        }
    }
}

@Composable
private fun EmptyInbox(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.xxl, vertical = Spacing.xxl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.md, Alignment.CenterVertically),
    ) {
        Box(
            modifier = Modifier
                .size(64.dp)
                .clip(RoundedCornerShape(Spacing.radiusMedium))
                .background(BrandColor.Primary.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.Filled.NotificationsActive,
                contentDescription = null,
                tint = BrandColor.Primary,
                modifier = Modifier.size(32.dp),
            )
        }
        Text(
            text = stringResource(R.string.inbox_empty_title),
            style = BrandText.headline,
            color = BrandColor.textPrimary(),
            textAlign = TextAlign.Center,
        )
        Text(
            text = stringResource(R.string.inbox_empty_body),
            style = BrandText.body,
            color = BrandColor.textTertiary(),
            textAlign = TextAlign.Center,
        )
    }
}

// ── Helpers ────────────────────────────────────────────────────────────────

private fun NotificationKind.icon(): ImageVector = when (this) {
    NotificationKind.WeeklyDigest -> Icons.Filled.Campaign
    NotificationKind.BudgetAlert -> Icons.Filled.Warning
    NotificationKind.Anomaly -> Icons.Filled.Bolt
    NotificationKind.Achievement -> Icons.Filled.Celebration
    NotificationKind.GoalMilestone -> Icons.Filled.Flag
    NotificationKind.SystemMessage -> Icons.Filled.Info
}

private fun NotificationKind.tint(): Color = when (this) {
    NotificationKind.WeeklyDigest -> BrandColor.Info
    NotificationKind.BudgetAlert -> BrandColor.Warning
    NotificationKind.Anomaly -> BrandColor.Expense
    NotificationKind.Achievement -> Color(0xFFF59E0B)
    NotificationKind.GoalMilestone -> BrandColor.Income
    NotificationKind.SystemMessage -> BrandColor.Primary
}

private fun relativeTime(epochMillis: Long): String {
    val now = Instant.now()
    val then = Instant.ofEpochMilli(epochMillis)
    val minutes = ChronoUnit.MINUTES.between(then, now).coerceAtLeast(0)
    return when {
        minutes < 1 -> "just now"
        minutes < 60 -> "${minutes}m ago"
        minutes < 24 * 60 -> "${minutes / 60}h ago"
        minutes < 7 * 24 * 60 -> "${minutes / (24 * 60)}d ago"
        else -> DateTimeFormatter.ofPattern("MMM d")
            .withZone(ZoneId.systemDefault())
            .format(then)
    }
}
