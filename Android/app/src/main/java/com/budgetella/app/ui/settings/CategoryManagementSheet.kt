package com.budgetella.app.ui.settings

import androidx.compose.foundation.background
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
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
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
import com.budgetella.app.ui.transactions.iconForSlug

/**
 * Category management sheet — port of iOS CategoryManagementView. Lists every
 * category for the active user grouped by income / expense; tap a row to
 * rename, long-press to delete, "+" to add a new one. No paywall yet —
 * iOS gates `add` behind premium; Android currently leaves it open.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoryManagementSheet(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val vm: CategoryManagementViewModel = hiltViewModel()
    val state by vm.state.collectAsStateWithLifecycle()

    var editing by remember { mutableStateOf<CategoryEntity?>(null) }
    var deleting by remember { mutableStateOf<CategoryEntity?>(null) }
    var addingType by remember { mutableStateOf<TransactionType?>(null) }

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

            // Income section
            CategorySection(
                titleRes = R.string.category_mgmt_section_income,
                items = state.income,
                onRename = { editing = it },
                onDelete = { deleting = it },
                onAdd = { addingType = TransactionType.Income },
            )

            // Expense section
            CategorySection(
                titleRes = R.string.category_mgmt_section_expense,
                items = state.expense,
                onRename = { editing = it },
                onDelete = { deleting = it },
                onAdd = { addingType = TransactionType.Expense },
            )
        }
    }

    // Rename dialog
    editing?.let { cat ->
        RenameDialog(
            category = cat,
            onDismiss = { editing = null },
            onConfirm = { newName ->
                vm.rename(cat, newName)
                editing = null
            },
        )
    }

    // Delete confirmation
    deleting?.let { cat ->
        AlertDialog(
            onDismissRequest = { deleting = null },
            title = { Text(stringResource(R.string.category_mgmt_delete_title)) },
            text = { Text(stringResource(R.string.category_mgmt_delete_body)) },
            confirmButton = {
                TextButton(onClick = {
                    vm.delete(cat)
                    deleting = null
                }) {
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

    // Add new category dialog
    addingType?.let { type ->
        AddCategoryDialog(
            type = type,
            onDismiss = { addingType = null },
            onConfirm = { name, colorHex, iconName ->
                vm.add(name = name, type = type, colorHex = colorHex, iconName = iconName)
                addingType = null
            },
        )
    }
}

@Composable
private fun CategorySection(
    titleRes: Int,
    items: List<CategoryEntity>,
    onRename: (CategoryEntity) -> Unit,
    onDelete: (CategoryEntity) -> Unit,
    onAdd: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.xs)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = stringResource(titleRes),
                style = BrandText.caption2,
                color = BrandColor.textTertiary(),
                modifier = Modifier
                    .weight(1f)
                    .padding(start = Spacing.md),
            )
            IconButton(onClick = onAdd) {
                Icon(
                    imageVector = Icons.Filled.Add,
                    contentDescription = null,
                    tint = BrandColor.Primary,
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CategoryRow(
    category: CategoryEntity,
    onRename: () -> Unit,
    onDelete: () -> Unit,
) {
    val tint = runCatching {
        Color(android.graphics.Color.parseColor(category.colorHex))
    }.getOrNull() ?: BrandColor.Primary
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(onClick = onRename, onLongClick = onDelete)
            .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(tint.copy(alpha = 0.18f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = iconForSlug(CategorySlug.fromRaw(category.slug)),
                contentDescription = null,
                tint = tint,
                modifier = Modifier.size(18.dp),
            )
        }
        Spacer(Modifier.width(Spacing.md))
        Text(
            text = com.budgetella.app.core.locale.displayCategoryName(category),
            style = BrandText.body,
            color = BrandColor.textPrimary(),
            modifier = Modifier.weight(1f),
        )
        IconButton(onClick = onRename) {
            Icon(
                imageVector = Icons.Filled.Edit,
                contentDescription = stringResource(R.string.common_rename),
                tint = BrandColor.textTertiary(),
                modifier = Modifier.size(18.dp),
            )
        }
        IconButton(onClick = onDelete) {
            Icon(
                imageVector = Icons.Filled.Delete,
                contentDescription = stringResource(R.string.common_delete),
                tint = BrandColor.Expense.copy(alpha = 0.85f),
                modifier = Modifier.size(18.dp),
            )
        }
    }
}

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
        text = {
            OutlinedTextField(
                value = input,
                onValueChange = { input = it },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp),
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Words,
                    imeAction = ImeAction.Done,
                ),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BrandColor.Primary,
                    unfocusedBorderColor = BrandColor.borderMedium(),
                    cursorColor = BrandColor.Primary,
                ),
            )
        },
        confirmButton = {
            TextButton(
                enabled = input.trim().isNotEmpty() && input.trim() != category.name,
                onClick = { onConfirm(input) },
            ) {
                Text(stringResource(R.string.common_save), color = BrandColor.Primary)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_cancel))
            }
        },
        containerColor = BrandColor.surface(),
    )
}

@Composable
private fun AddCategoryDialog(
    type: TransactionType,
    onDismiss: () -> Unit,
    onConfirm: (name: String, colorHex: String, iconName: String) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    // Custom categories ship with a neutral colour + tag icon — users can't
    // pick custom colours yet (matches iOS' AddCategorySheet v1 simplicity).
    val defaultColor = "#6E5BFF"
    val defaultIcon = "tag"
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = stringResource(
                    if (type == TransactionType.Income) R.string.category_mgmt_add_title_income
                    else R.string.category_mgmt_add_title_expense
                ),
            )
        },
        text = {
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                singleLine = true,
                placeholder = { Text(stringResource(R.string.category_mgmt_name_placeholder)) },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp),
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Words,
                    imeAction = ImeAction.Done,
                ),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BrandColor.Primary,
                    unfocusedBorderColor = BrandColor.borderMedium(),
                    cursorColor = BrandColor.Primary,
                ),
            )
        },
        confirmButton = {
            TextButton(
                enabled = name.trim().isNotBlank(),
                onClick = { onConfirm(name, defaultColor, defaultIcon) },
            ) {
                Text(stringResource(R.string.common_save), color = BrandColor.Primary)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_cancel))
            }
        },
        containerColor = BrandColor.surface(),
    )
}
