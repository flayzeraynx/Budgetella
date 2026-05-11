package com.budgetella.app.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.core.design.moneyText

/**
 * Profile sheet — port of iOS ProfileView (minimal v1 cut).
 *
 * Shows avatar, name, email, and three at-a-glance stat tiles. Achievements
 * + edit-profile actions are deferred to v1.1 — the README documents these
 * as known gaps.
 */
@Composable
fun ProfileSheet(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val vm: ProfileViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()

    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(BrandColor.background()),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.xl)
                .padding(top = Spacing.lg, bottom = Spacing.xxl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.lg),
        ) {
            Text(
                text = stringResource(R.string.profile_title),
                style = BrandText.largeTitle,
                color = BrandColor.textPrimary(),
                modifier = Modifier.fillMaxWidth(),
            )

            // Avatar + name + email
            Avatar(photoUrl = state.photoUrl, size = 96.dp)
            Spacer(Modifier.height(Spacing.xs))
            Text(
                text = state.displayName?.takeIf { it.isNotBlank() } ?: (state.email ?: ""),
                style = BrandText.title.copy(fontWeight = FontWeight.Bold),
                color = BrandColor.textPrimary(),
            )
            state.email?.takeIf { it.isNotBlank() }?.let {
                Text(
                    text = it,
                    style = BrandText.body,
                    color = BrandColor.textSecondary(),
                )
            }

            Spacer(Modifier.height(Spacing.md))

            // Stats grid (3 tiles)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.md),
            ) {
                StatTile(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Filled.Receipt,
                    iconTint = BrandColor.Primary,
                    label = stringResource(R.string.profile_stat_transactions),
                    value = state.transactionCount.toString(),
                )
                StatTile(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Filled.Savings,
                    iconTint = BrandColor.Income,
                    label = stringResource(R.string.profile_stat_total_saved),
                    value = moneyText(state.totalSavedMinor),
                )
                StatTile(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Filled.LocalFireDepartment,
                    iconTint = BrandColor.Warning,
                    label = stringResource(R.string.profile_stat_streak),
                    value = state.dailyStreak.toString(),
                )
            }

            // This-month section — port of iOS ProfileView.monthStatusCard.
            ProfileSectionHeader(stringResource(R.string.profile_section_this_month))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(Spacing.radiusMedium))
                    .background(BrandColor.surface().copy(alpha = 0.4f))
                    .padding(Spacing.md),
                verticalArrangement = Arrangement.spacedBy(Spacing.sm),
            ) {
                MonthRow(
                    label = stringResource(R.string.profile_month_income),
                    value = moneyText(state.monthIncomeMinor),
                    tint = BrandColor.Income,
                )
                MonthRow(
                    label = stringResource(R.string.profile_month_expense),
                    value = moneyText(state.monthExpenseMinor),
                    tint = BrandColor.Expense,
                )
                MonthRow(
                    label = stringResource(R.string.profile_month_net),
                    value = moneyText(state.monthSavedMinor),
                    tint = if (state.monthSavedMinor >= 0) BrandColor.Income else BrandColor.Expense,
                    emphasised = true,
                )
            }

            // Achievements grid — 6 tiles in 3 columns. iOS ProfileView.achievements.
            ProfileSectionHeader(stringResource(R.string.profile_section_achievements))
            AchievementsGrid(
                items = remember(
                    state.transactionCount,
                    state.totalSavedMinor,
                    state.dailyStreak,
                ) {
                    buildAchievements(
                        txCount = state.transactionCount,
                        savedMinor = state.totalSavedMinor,
                        streak = state.dailyStreak,
                    )
                },
            )
        }
    }
}

@Composable
private fun ProfileSectionHeader(label: String) {
    Text(
        text = label,
        style = BrandText.caption2,
        color = BrandColor.textTertiary(),
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = Spacing.xs, top = Spacing.sm, bottom = Spacing.xs),
    )
}

@Composable
private fun MonthRow(
    label: String,
    value: String,
    tint: androidx.compose.ui.graphics.Color,
    emphasised: Boolean = false,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            style = if (emphasised) BrandText.subheadline else BrandText.body,
            color = BrandColor.textSecondary(),
            modifier = Modifier.weight(1f),
        )
        Text(
            text = value,
            style = if (emphasised) BrandText.subheadline.copy(fontWeight = FontWeight.SemiBold)
                    else BrandText.body.copy(fontWeight = FontWeight.SemiBold),
            color = tint,
        )
    }
}

// ── Achievements ──────────────────────────────────────────────────────────

private data class Achievement(
    val emoji: String,
    val labelRes: Int,
    val isUnlocked: Boolean,
    val tint: androidx.compose.ui.graphics.Color,
)

private fun buildAchievements(
    txCount: Int,
    savedMinor: Long,
    streak: Int,
): List<Achievement> = listOf(
    Achievement(
        emoji = "🔥",
        labelRes = R.string.profile_achievement_first,
        isUnlocked = txCount > 0,
        tint = androidx.compose.ui.graphics.Color(0xFFFF6B35),
    ),
    Achievement(
        emoji = "📅",
        labelRes = R.string.profile_achievement_streak10,
        isUnlocked = streak >= 10,
        tint = BrandColor.Primary,
    ),
    Achievement(
        emoji = "💼",
        labelRes = R.string.profile_achievement_tx50,
        isUnlocked = txCount >= 50,
        tint = BrandColor.Income,
    ),
    Achievement(
        emoji = "💰",
        labelRes = R.string.profile_achievement_save1k,
        // 1,000 in major units → 100,000 minor units (kuruş/cents).
        isUnlocked = savedMinor >= 100_000L,
        tint = androidx.compose.ui.graphics.Color(0xFFFFD700),
    ),
    Achievement(
        emoji = "⭐",
        labelRes = R.string.profile_achievement_tx100,
        isUnlocked = txCount >= 100,
        tint = androidx.compose.ui.graphics.Color(0xFF8B5CF6),
    ),
    Achievement(
        emoji = "🎯",
        labelRes = R.string.profile_achievement_budget_goal,
        isUnlocked = false,
        tint = BrandColor.Expense,
    ),
)

@Composable
private fun AchievementsGrid(items: List<Achievement>) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
        items.chunked(3).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
            ) {
                row.forEach { item ->
                    AchievementTile(item = item, modifier = Modifier.weight(1f))
                }
                // Pad the row if it ended short (the last row only has 0 items
                // in our case, so this is defensive for future additions).
                repeat(3 - row.size) {
                    Box(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun AchievementTile(item: Achievement, modifier: Modifier = Modifier) {
    val alpha = if (item.isUnlocked) 1f else 0.35f
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(item.tint.copy(alpha = if (item.isUnlocked) 0.18f else 0.08f))
            .padding(vertical = Spacing.md, horizontal = Spacing.sm),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = item.emoji,
            style = BrandText.title,
            modifier = Modifier.graphicsLayer { this.alpha = alpha },
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = stringResource(item.labelRes),
            style = BrandText.caption,
            color = if (item.isUnlocked) BrandColor.textPrimary() else BrandColor.textTertiary(),
            maxLines = 2,
        )
    }
}

@Composable
private fun Avatar(photoUrl: String?, size: Dp) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(BrandColor.Primary.copy(alpha = 0.2f)),
        contentAlignment = Alignment.Center,
    ) {
        if (!photoUrl.isNullOrBlank()) {
            AsyncImage(
                model = photoUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(size)
                    .clip(CircleShape),
                contentScale = ContentScale.Crop,
            )
        } else {
            Icon(
                imageVector = Icons.Filled.AccountCircle,
                contentDescription = null,
                tint = BrandColor.Primary,
                modifier = Modifier.size((size.value * 0.6f).dp),
            )
        }
    }
}

@Composable
private fun StatTile(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    iconTint: androidx.compose.ui.graphics.Color,
    label: String,
    value: String,
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(Spacing.radiusMedium))
            .background(BrandColor.surface().copy(alpha = 0.4f))
            .padding(Spacing.md),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(RoundedCornerShape(Spacing.radiusSmall))
                .background(iconTint.copy(alpha = 0.18f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.size(18.dp),
            )
        }
        Spacer(Modifier.height(Spacing.xs))
        Text(
            text = value,
            style = BrandText.subheadline.copy(fontWeight = FontWeight.SemiBold),
            color = BrandColor.textPrimary(),
        )
        Text(
            text = label,
            style = BrandText.caption,
            color = BrandColor.textTertiary(),
        )
    }
}
