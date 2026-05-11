package com.budgetella.app.ui.transactions

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.local.entity.TransactionEntity
import com.budgetella.app.data.model.CategorySlug
import com.budgetella.app.data.model.RecurringInterval
import com.budgetella.app.data.model.TransactionType
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Add / Edit transaction bottom sheet.
 *
 * `existing == null` opens a fresh add form. Pass a transaction to edit it —
 * the sheet pre-fills every field and exposes a Delete button.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditTransactionSheet(
    existing: TransactionEntity?,
    onDismiss: () -> Unit,
) {
    val vm: AddEditTransactionViewModel = hiltViewModel()
    val form by vm.form.collectAsStateWithLifecycle()
    val categories by vm.categories.collectAsStateWithLifecycle()

    // Initialise (or reset) the form on each open. Stable key = the editing
    // id, so add → edit → add cycles all flow through.
    LaunchedEffect(existing?.id) {
        if (existing == null) vm.startAdd() else vm.startEdit(existing)
    }
    // Once the categories list is non-empty, auto-select the first one of the
    // current type when nothing is selected yet.
    LaunchedEffect(categories, form.type, form.categoryId) {
        if (categories.isNotEmpty()) vm.ensureCategoryDefault()
    }

    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = BrandColor.background2(),
        dragHandle = null,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.xl)
                .navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(Spacing.lg),
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = Spacing.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = stringResource(if (form.isEditing) R.string.edit_title else R.string.add_title),
                    style = BrandText.title,
                    color = BrandColor.textPrimary(),
                    modifier = Modifier.weight(1f),
                )
                TextButton(onClick = { scope.launch { sheetState.hide(); onDismiss() } }) {
                    Text(stringResource(R.string.common_cancel), color = BrandColor.textTertiary())
                }
            }

            // Type toggle + inline date pill on the right — matches the new
            // header layout the user asked for. Tap the date pill to open a
            // picker; works for both add and edit modes.
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                TypeToggle(
                    type = form.type,
                    onChange = vm::setType,
                )
                Spacer(Modifier.weight(1f))
                DatePill(
                    dateMillis = form.dateMillis,
                    onDateChange = vm::setDate,
                )
            }

            // Amount — auto-focused with numeric keyboard so the user can
            // start typing immediately on open. The FocusRequester is keyed
            // to the editing id so re-opening for a different transaction
            // re-requests focus.
            val focus = remember { FocusRequester() }
            LaunchedEffect(form.editingId, form.isEditing) {
                // Only steal focus on a fresh "add" — pre-filled edit forms
                // shouldn't pop the keyboard since the user is here to tweak,
                // not type from scratch.
                if (!form.isEditing) focus.requestFocus()
            }
            OutlinedTextField(
                value = form.amountInput,
                onValueChange = vm::setAmountInput,
                label = { Text(stringResource(R.string.add_amount_label)) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal,
                    imeAction = ImeAction.Next,
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(focus),
                shape = RoundedCornerShape(Spacing.radiusMedium),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BrandColor.Primary,
                    unfocusedBorderColor = BrandColor.borderMedium(),
                    focusedLabelColor = BrandColor.Primary,
                    cursorColor = BrandColor.Primary,
                ),
            )

            // Note — moved directly under Amount per user request.
            OutlinedTextField(
                value = form.note,
                onValueChange = vm::setNote,
                label = { Text(stringResource(R.string.add_note_label)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(Spacing.radiusMedium),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BrandColor.Primary,
                    unfocusedBorderColor = BrandColor.borderMedium(),
                    focusedLabelColor = BrandColor.Primary,
                    cursorColor = BrandColor.Primary,
                ),
            )

            // Recurring toggle + interval chips — port of iOS recurringRow.
            RecurringRow(
                isRecurring = form.isRecurring,
                interval = form.recurringInterval,
                onToggle = vm::setRecurring,
                onIntervalChange = vm::setRecurringInterval,
            )

            // Category picker
            Text(
                text = stringResource(R.string.add_category_label),
                style = BrandText.caption,
                color = BrandColor.textTertiary(),
            )
            CategoryGrid(
                categories = categories.filter { it.type == form.type },
                selectedId = form.categoryId,
                onSelect = vm::setCategory,
            )

            // Save / Delete
            Button(
                onClick = {
                    vm.save {
                        scope.launch { sheetState.hide() }
                        onDismiss()
                    }
                },
                enabled = form.canSave,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(Spacing.radiusFull),
                colors = ButtonDefaults.buttonColors(containerColor = BrandColor.Primary),
            ) {
                Text(stringResource(R.string.add_save), style = BrandText.subheadline)
            }
            if (form.isEditing) {
                TextButton(
                    onClick = {
                        vm.delete {
                            scope.launch { sheetState.hide() }
                            onDismiss()
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(stringResource(R.string.common_delete), color = BrandColor.Expense)
                }
            }
            Spacer(Modifier.height(Spacing.lg))
        }
    }
}

// ── Sub-components ─────────────────────────────────────────────────────────

@Composable
private fun TypeToggle(type: TransactionType, onChange: (TransactionType) -> Unit) {
    Row(
        modifier = Modifier
            .clip(CircleShape)
            .background(BrandColor.surface().copy(alpha = 0.5f))
            .padding(3.dp),
    ) {
        TogglePill(
            label = stringResource(R.string.transactions_filter_expense),
            selected = type == TransactionType.Expense,
            accent = BrandColor.Expense,
            onClick = { onChange(TransactionType.Expense) },
        )
        TogglePill(
            label = stringResource(R.string.transactions_filter_income),
            selected = type == TransactionType.Income,
            accent = BrandColor.Income,
            onClick = { onChange(TransactionType.Income) },
        )
    }
}

@Composable
private fun TogglePill(label: String, selected: Boolean, accent: Color, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(if (selected) accent else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
    ) {
        Text(
            text = label,
            style = BrandText.subheadline,
            color = if (selected) Color.White else BrandColor.textSecondary(),
        )
    }
}

@Composable
private fun CategoryGrid(
    categories: List<CategoryEntity>,
    selectedId: String?,
    onSelect: (String) -> Unit,
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(4),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
        modifier = Modifier.height(220.dp),
    ) {
        items(items = categories, key = { it.id }) { cat ->
            val tint = runCatching { Color(android.graphics.Color.parseColor(cat.colorHex)) }.getOrNull()
                ?: BrandColor.Primary
            val isSelected = cat.id == selectedId
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier
                    .clip(RoundedCornerShape(Spacing.radiusSmall))
                    .clickable { onSelect(cat.id) }
                    .padding(vertical = Spacing.xs),
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(if (isSelected) tint else tint.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = iconForSlug(CategorySlug.fromRaw(cat.slug)),
                        contentDescription = null,
                        tint = if (isSelected) Color.White else tint,
                        modifier = Modifier.size(22.dp),
                    )
                }
                Text(
                    text = com.budgetella.app.core.locale.displayCategoryName(cat),
                    style = BrandText.caption,
                    color = if (isSelected) BrandColor.textPrimary() else BrandColor.textTertiary(),
                    maxLines = 1,
                )
            }
        }
    }
}

/**
 * Compact date pill sitting next to the type toggle in the header. Tap to
 * open the system DatePicker dialog. Replaces the bigger labelled DateField
 * the sheet used to render in its own row.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DatePill(dateMillis: Long, onDateChange: (Long) -> Unit) {
    var showPicker by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier
            .clip(CircleShape)
            .background(BrandColor.surface().copy(alpha = 0.5f))
            .clickable { showPicker = true }
            .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.Filled.CalendarToday,
            contentDescription = null,
            tint = BrandColor.textSecondary(),
            modifier = Modifier.size(14.dp),
        )
        Spacer(Modifier.size(6.dp))
        Text(
            text = formatDateShort(dateMillis),
            style = BrandText.footnote,
            color = BrandColor.textPrimary(),
        )
    }

    if (showPicker) {
        val state = rememberDatePickerState(initialSelectedDateMillis = dateMillis)
        DatePickerDialog(
            onDismissRequest = { showPicker = false },
            confirmButton = {
                TextButton(onClick = {
                    state.selectedDateMillis?.let(onDateChange)
                    showPicker = false
                }) { Text(stringResource(R.string.common_done)) }
            },
            dismissButton = {
                TextButton(onClick = { showPicker = false }) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
        ) {
            DatePicker(state = state)
        }
    }
}

@Composable
private fun RecurringRow(
    isRecurring: Boolean,
    interval: RecurringInterval,
    onToggle: (Boolean) -> Unit,
    onIntervalChange: (RecurringInterval) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.xs)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Spacing.radiusMedium))
                .background(BrandColor.surface().copy(alpha = 0.4f))
                .padding(horizontal = Spacing.md, vertical = Spacing.sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = Icons.Filled.Repeat,
                contentDescription = null,
                tint = BrandColor.textTertiary(),
                modifier = Modifier.size(16.dp),
            )
            Spacer(Modifier.size(Spacing.sm))
            Text(
                text = stringResource(R.string.add_recurring_label),
                style = BrandText.body,
                color = BrandColor.textSecondary(),
                modifier = Modifier.weight(1f),
            )
            Switch(
                checked = isRecurring,
                onCheckedChange = onToggle,
                colors = SwitchDefaults.colors(
                    checkedThumbColor = Color.White,
                    checkedTrackColor = BrandColor.Primary,
                    uncheckedThumbColor = Color.White,
                    uncheckedTrackColor = BrandColor.borderMedium(),
                ),
            )
        }
        if (isRecurring) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                RecurringInterval.entries.forEach { entry ->
                    IntervalChip(
                        label = stringResource(intervalLabelRes(entry)),
                        selected = entry == interval,
                        onClick = { onIntervalChange(entry) },
                        modifier = Modifier.weight(1f),
                    )
                }
            }
        }
    }
}

@Composable
private fun IntervalChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .clip(CircleShape)
            .background(
                if (selected) BrandColor.Primary
                else BrandColor.surface().copy(alpha = 0.5f)
            )
            .clickable(onClick = onClick)
            .padding(vertical = Spacing.sm),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = BrandText.footnote,
            color = if (selected) Color.White else BrandColor.textTertiary(),
        )
    }
}

private fun intervalLabelRes(interval: RecurringInterval): Int = when (interval) {
    RecurringInterval.Daily -> R.string.recurring_daily
    RecurringInterval.Weekly -> R.string.recurring_weekly
    RecurringInterval.Monthly -> R.string.recurring_monthly
    RecurringInterval.Yearly -> R.string.recurring_yearly
}

private fun formatDateShort(epochMillis: Long): String =
    DateTimeFormatter.ofPattern("d MMM yyyy", Locale.getDefault())
        .withZone(ZoneId.systemDefault())
        .format(Instant.ofEpochMilli(epochMillis))

private fun formatDateFull(epochMillis: Long): String =
    DateTimeFormatter.ofPattern("EEE, d MMM yyyy", Locale.getDefault())
        .withZone(ZoneId.systemDefault())
        .format(Instant.ofEpochMilli(epochMillis))
