package com.budgetella.app.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LocalOffer
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Pets
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.model.CategorySlug
import com.budgetella.app.data.model.TransactionType
import com.budgetella.app.ui.paywall.PaywallScreen
import com.budgetella.app.ui.transactions.iconForSlug

// ── Icon + colour palettes ────────────────────────────────────────────────────
// Mirrors iOS CategoryManagementView: same 15 icons, same 10 hex colours.

private val categoryIconOptions: List<Pair<String, ImageVector>> = listOf(
    "tag"            to Icons.Filled.LocalOffer,
    "cart"           to Icons.Filled.ShoppingCart,
    "fork.knife"     to Icons.Filled.Restaurant,
    "car"            to Icons.Filled.DirectionsCar,
    "house"          to Icons.Filled.Home,
    "heart"          to Icons.Filled.Favorite,
    "gamecontroller" to Icons.Filled.SportsEsports,
    "book"           to Icons.AutoMirrored.Filled.MenuBook,
    "airplane"       to Icons.Filled.Flight,
    "music.note"     to Icons.Filled.MusicNote,
    "dumbbell"       to Icons.Filled.FitnessCenter,
    "bag"            to Icons.Filled.ShoppingBag,
    "creditcard"     to Icons.Filled.CreditCard,
    "gift"           to Icons.Filled.CardGiftcard,
    "pawprint"       to Icons.Filled.Pets,
)

private val categoryColorOptions = listOf(
    "#6E5BFF", "#FF6B6B", "#4CAF50", "#FF9800", "#2196F3",
    "#E91E63", "#9C27B0", "#00BCD4", "#8BC34A", "#FF5722",
)

/** Resolves a custom category's [iconName] field to a Material [ImageVector]. */
private fun iconForCustom(iconName: String?): ImageVector =
    categoryIconOptions.firstOrNull { it.first == iconName }?.second ?: Icons.Filled.LocalOffer

/** Picks the right icon: slug-based for defaults, iconName-based for custom. */
@Composable
private fun categoryIcon(category: CategoryEntity): ImageVector =
    if (category.slug != null) iconForSlug(CategorySlug.fromRaw(category.slug))
    else iconForCustom(category.iconName)

private fun parseColor(hex: String?): Color? =
    hex?.runCatching { Color(android.graphics.Color.parseColor(this)) }?.getOrNull()

// ── Sheet ─────────────────────────────────────────────────────────────────────

/**
 * Category management sheet — port of iOS CategoryManagementView.
 *
 * Rules:
 *  - Default categories (isDefault = true) are read-only: no edit/delete actions shown.
 *  - "+" (add new category) is premium-gated. In DEBUG builds always enabled.
 *  - Custom categories show an "Özel" badge and expose edit + delete icons.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoryManagementSheet(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val vm: CategoryManagementViewModel = hiltViewModel()
    val state     by vm.state.collectAsStateWithLifecycle()
    val isPremium by vm.isPremium.collectAsStateWithLifecycle()

    var editing     by remember { mutableStateOf<CategoryEntity?>(null) }
    var deleting    by remember { mutableStateOf<CategoryEntity?>(null) }
    var addingType  by remember { mutableStateOf<TransactionType?>(null) }
    var showPaywall by remember { mutableStateOf(false) }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(BrandColor.background()),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.lg)
                .padding(top = Spacing.md, bottom = Spacing.xxl),
            verticalArrangement = Arrangement.spacedBy(Spacing.lg),
        ) {
            // Title + close
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.category_mgmt_title),
                    style = BrandText.largeTitle,
                    color = BrandColor.textPrimary(),
                    modifier = Modifier.weight(1f),
                )
                TextButton(onClick = onDismiss) {
                    Text(stringResource(R.string.common_done), color = BrandColor.Primary)
                }
            }

            CategorySection(
                titleRes  = R.string.category_mgmt_section_income,
                items     = state.income,
                isPremium = isPremium,
                onRename  = { editing = it },
                onDelete  = { deleting = it },
                onAdd     = { addingType = TransactionType.Income },
                onPaywall = { showPaywall = true },
            )

            CategorySection(
                titleRes  = R.string.category_mgmt_section_expense,
                items     = state.expense,
                isPremium = isPremium,
                onRename  = { editing = it },
                onDelete  = { deleting = it },
                onAdd     = { addingType = TransactionType.Expense },
                onPaywall = { showPaywall = true },
            )
        }
    }

    // Rename dialog (guard in row ensures only non-default reach here)
    editing?.let { cat ->
        RenameDialog(
            category = cat,
            onDismiss = { editing = null },
            onConfirm = { newName -> vm.rename(cat, newName); editing = null },
        )
    }

    // Delete confirmation
    deleting?.let { cat ->
        AlertDialog(
            onDismissRequest = { deleting = null },
            title  = { Text(stringResource(R.string.category_mgmt_delete_title)) },
            text   = { Text(stringResource(R.string.category_mgmt_delete_body)) },
            confirmButton = {
                TextButton(onClick = { vm.delete(cat); deleting = null }) {
                    Text(stringResource(R.string.common_delete), color = BrandColor.Expense)
                }
            },
            dismissButton = {
                TextButton(onClick = { deleting = null }) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
            containerColor = BrandColor.surface(),
        )
    }

    // Add sheet — full iOS-style with icon + colour pickers
    addingType?.let { type ->
        AddCategorySheet(
            initialType = type,
            onDismiss   = { addingType = null },
            onConfirm   = { name, colorHex, iconName, resolvedType ->
                vm.add(name = name, type = resolvedType, colorHex = colorHex, iconName = iconName)
                addingType = null
            },
        )
    }

    // Paywall sheet — shown when non-premium user taps "+"
    if (showPaywall) {
        ModalBottomSheet(
            onDismissRequest = { showPaywall = false },
            sheetState       = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor   = BrandColor.background(),
            dragHandle       = null,
        ) {
            PaywallScreen(onClose = { showPaywall = false })
        }
    }
}

// ── Section ───────────────────────────────────────────────────────────────────

@Composable
private fun CategorySection(
    titleRes: Int,
    items: List<CategoryEntity>,
    isPremium: Boolean,
    onRename: (CategoryEntity) -> Unit,
    onDelete: (CategoryEntity) -> Unit,
    onAdd: () -> Unit,
    onPaywall: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.xs)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text     = stringResource(titleRes),
                style    = BrandText.caption2,
                color    = BrandColor.textTertiary(),
                modifier = Modifier.weight(1f).padding(start = Spacing.md),
            )
            IconButton(onClick = { if (isPremium) onAdd() else onPaywall() }) {
                Icon(
                    imageVector     = Icons.Filled.Add,
                    contentDescription = null,
                    tint            = BrandColor.Primary,
                )
            }
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Spacing.radiusMedium))
                .background(BrandColor.surface().copy(alpha = 0.4f))
                .padding(vertical = Spacing.xs),
        ) {
            items.forEachIndexed { index, cat ->
                CategoryRow(
                    category = cat,
                    onRename = { onRename(cat) },
                    onDelete = { onDelete(cat) },
                )
                if (index != items.lastIndex) {
                    Box(
                        modifier = Modifier
                            .padding(start = 64.dp, end = Spacing.md)
                            .fillMaxWidth()
                            .height(0.5.dp)
                            .background(BrandColor.borderSubtle()),
                    )
                }
            }
        }
    }
}

// ── Row ───────────────────────────────────────────────────────────────────────

@Composable
private fun CategoryRow(
    category: CategoryEntity,
    onRename: () -> Unit,
    onDelete: () -> Unit,
) {
    val tint = parseColor(category.colorHex) ?: BrandColor.Primary
    // A category is editable only if it is neither flagged as default NOR has a
    // system slug — slug is the authoritative guard in case `isDefault` was ever
    // reset by a legacy iOS→Firestore sync that didn't write the field.
    val isEditable = !category.isDefault && category.slug == null

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (isEditable) Modifier.combinedClickable(onClick = onRename, onLongClick = onDelete)
                else Modifier
            )
            .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Icon circle
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.18f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector        = categoryIcon(category),
                contentDescription = null,
                tint               = tint,
                modifier           = Modifier.size(18.dp),
            )
        }
        Spacer(Modifier.width(Spacing.md))
        Text(
            text     = com.budgetella.app.core.locale.displayCategoryName(category),
            style    = BrandText.body,
            color    = BrandColor.textPrimary(),
            modifier = Modifier.weight(1f),
        )
        // "Özel" badge — custom categories only
        if (isEditable) {
            Text(
                text     = stringResource(R.string.category_mgmt_custom_badge),
                style    = BrandText.caption2,
                color    = BrandColor.Primary,
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(BrandColor.Primary.copy(alpha = 0.12f))
                    .padding(horizontal = 6.dp, vertical = 2.dp),
            )
            Spacer(Modifier.width(4.dp))
        }
        // Edit/Delete — hidden for default categories (mirrors iOS swipe-action guard)
        if (isEditable) {
            IconButton(onClick = onRename, modifier = Modifier.size(36.dp)) {
                Icon(
                    imageVector        = Icons.Filled.Edit,
                    contentDescription = stringResource(R.string.common_rename),
                    tint               = BrandColor.textTertiary(),
                    modifier           = Modifier.size(18.dp),
                )
            }
            IconButton(onClick = onDelete, modifier = Modifier.size(36.dp)) {
                Icon(
                    imageVector        = Icons.Filled.Delete,
                    contentDescription = stringResource(R.string.common_delete),
                    tint               = BrandColor.Expense.copy(alpha = 0.85f),
                    modifier           = Modifier.size(18.dp),
                )
            }
        }
    }
}

// ── Rename dialog ─────────────────────────────────────────────────────────────

@Composable
private fun RenameDialog(
    category: CategoryEntity,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit,
) {
    var input by remember { mutableStateOf(category.name) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.category_mgmt_rename_title)) },
        text  = {
            OutlinedTextField(
                value         = input,
                onValueChange = { input = it },
                singleLine    = true,
                modifier      = Modifier.fillMaxWidth(),
                shape         = RoundedCornerShape(10.dp),
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Words,
                    imeAction      = ImeAction.Done,
                ),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor   = BrandColor.Primary,
                    unfocusedBorderColor = BrandColor.borderMedium(),
                    cursorColor          = BrandColor.Primary,
                ),
            )
        },
        confirmButton = {
            TextButton(
                enabled = input.trim().isNotEmpty() && input.trim() != category.name,
                onClick = { onConfirm(input) },
            ) { Text(stringResource(R.string.common_save), color = BrandColor.Primary) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.common_cancel)) }
        },
        containerColor = BrandColor.surface(),
    )
}

// ── Add category sheet ────────────────────────────────────────────────────────

/**
 * Full iOS-style sheet for creating a new custom category.
 *
 * Includes:
 *  - Live icon + colour preview
 *  - Category name field
 *  - Income / Expense type toggle
 *  - Icon picker (5 × 3 grid, 15 options)
 *  - Colour picker (5 × 2 grid, 10 options)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddCategorySheet(
    initialType: TransactionType,
    onDismiss: () -> Unit,
    onConfirm: (name: String, colorHex: String, iconName: String, type: TransactionType) -> Unit,
) {
    var name          by remember { mutableStateOf("") }
    var type          by remember { mutableStateOf(initialType) }
    var selectedIcon  by remember { mutableStateOf(categoryIconOptions.first().first) }
    var selectedColor by remember { mutableStateOf(categoryColorOptions.first()) }

    val previewColor = parseColor(selectedColor) ?: BrandColor.Primary
    val previewIcon  = iconForCustom(selectedIcon)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState       = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor   = BrandColor.background(),
        dragHandle       = null,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.lg)
                .padding(top = Spacing.md, bottom = Spacing.xxl),
            verticalArrangement = Arrangement.spacedBy(Spacing.lg),
        ) {
            // ── Header ──────────────────────────────────────────────────────
            Row(
                modifier          = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                TextButton(onClick = onDismiss) {
                    Text(stringResource(R.string.common_cancel), color = BrandColor.textSecondary())
                }
                Text(
                    text      = stringResource(R.string.category_mgmt_add_sheet_title),
                    style     = BrandText.headline,
                    color     = BrandColor.textPrimary(),
                    textAlign = TextAlign.Center,
                    modifier  = Modifier.weight(1f),
                )
                TextButton(
                    enabled = name.trim().isNotBlank(),
                    onClick = { onConfirm(name.trim(), selectedColor, selectedIcon, type) },
                ) {
                    Text(
                        text  = stringResource(R.string.category_mgmt_add_action),
                        color = if (name.trim().isNotBlank()) BrandColor.Primary
                                else BrandColor.textTertiary(),
                    )
                }
            }

            // ── Live preview ─────────────────────────────────────────────────
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(Spacing.radiusMedium))
                    .background(BrandColor.surface().copy(alpha = 0.4f))
                    .padding(Spacing.md),
                verticalAlignment    = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(Spacing.md),
            ) {
                Box(
                    modifier         = Modifier
                        .size(52.dp)
                        .clip(CircleShape)
                        .background(previewColor.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector        = previewIcon,
                        contentDescription = null,
                        tint               = previewColor,
                        modifier           = Modifier.size(24.dp),
                    )
                }
                Text(
                    text  = name.ifBlank { stringResource(R.string.category_mgmt_name_placeholder) },
                    style = BrandText.subheadline,
                    color = if (name.isBlank()) BrandColor.textTertiary() else BrandColor.textPrimary(),
                )
            }

            // ── Name field ───────────────────────────────────────────────────
            OutlinedTextField(
                value         = name,
                onValueChange = { name = it },
                singleLine    = true,
                placeholder   = { Text(stringResource(R.string.category_mgmt_name_placeholder)) },
                modifier      = Modifier.fillMaxWidth(),
                shape         = RoundedCornerShape(10.dp),
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Words,
                    imeAction      = ImeAction.Done,
                ),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor   = BrandColor.Primary,
                    unfocusedBorderColor = BrandColor.borderMedium(),
                    cursorColor          = BrandColor.Primary,
                    focusedTextColor     = BrandColor.textPrimary(),
                    unfocusedTextColor   = BrandColor.textPrimary(),
                ),
            )

            // ── Type toggle ──────────────────────────────────────────────────
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(Spacing.radiusFull))
                    .background(BrandColor.surface().copy(alpha = 0.5f))
                    .padding(4.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                listOf(TransactionType.Expense, TransactionType.Income).forEach { t ->
                    val selected = type == t
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(Spacing.radiusFull))
                            .background(if (selected) BrandColor.Primary else Color.Transparent)
                            .clickable { type = t }
                            .padding(vertical = 10.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text  = stringResource(
                                if (t == TransactionType.Expense) R.string.transactions_filter_expense
                                else R.string.transactions_filter_income,
                            ),
                            style = BrandText.subheadline,
                            color = if (selected) Color.White else BrandColor.textSecondary(),
                        )
                    }
                }
            }

            // ── Icon picker ──────────────────────────────────────────────────
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                Text(
                    text     = stringResource(R.string.category_mgmt_section_icon),
                    style    = BrandText.caption2,
                    color    = BrandColor.textTertiary(),
                    modifier = Modifier.padding(start = Spacing.xs),
                )
                categoryIconOptions.chunked(5).forEach { row ->
                    Row(
                        modifier              = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly,
                    ) {
                        row.forEach { (iconKey, iconVector) ->
                            val isSelected = selectedIcon == iconKey
                            Box(
                                modifier = Modifier
                                    .size(48.dp)
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(
                                        if (isSelected) previewColor.copy(alpha = 0.18f)
                                        else BrandColor.surface().copy(alpha = 0.35f)
                                    )
                                    .then(
                                        if (isSelected) Modifier.border(
                                            width  = 2.dp,
                                            color  = previewColor,
                                            shape  = RoundedCornerShape(12.dp),
                                        ) else Modifier
                                    )
                                    .clickable { selectedIcon = iconKey },
                                contentAlignment = Alignment.Center,
                            ) {
                                Icon(
                                    imageVector        = iconVector,
                                    contentDescription = null,
                                    tint               = if (isSelected) previewColor else BrandColor.textTertiary(),
                                    modifier           = Modifier.size(22.dp),
                                )
                            }
                        }
                    }
                    Spacer(Modifier.height(Spacing.xs))
                }
            }

            // ── Colour picker ────────────────────────────────────────────────
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                Text(
                    text     = stringResource(R.string.category_mgmt_section_color),
                    style    = BrandText.caption2,
                    color    = BrandColor.textTertiary(),
                    modifier = Modifier.padding(start = Spacing.xs),
                )
                categoryColorOptions.chunked(5).forEach { row ->
                    Row(
                        modifier              = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly,
                    ) {
                        row.forEach { hex ->
                            val color      = parseColor(hex) ?: BrandColor.Primary
                            val isSelected = selectedColor == hex
                            Box(
                                modifier = Modifier
                                    .size(40.dp)
                                    .clip(CircleShape)
                                    .background(color)
                                    .then(
                                        if (isSelected) Modifier.border(
                                            width = 3.dp,
                                            color = Color.White.copy(alpha = 0.85f),
                                            shape = CircleShape,
                                        ) else Modifier
                                    )
                                    .clickable { selectedColor = hex },
                                contentAlignment = Alignment.Center,
                            ) {
                                if (isSelected) {
                                    Icon(
                                        imageVector        = Icons.Filled.Check,
                                        contentDescription = null,
                                        tint               = Color.White,
                                        modifier           = Modifier.size(18.dp),
                                    )
                                }
                            }
                        }
                    }
                    Spacer(Modifier.height(Spacing.xs))
                }
            }
        }
    }
}
