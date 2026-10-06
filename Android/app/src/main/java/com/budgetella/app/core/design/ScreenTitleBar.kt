package com.budgetella.app.core.design

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp

/**
 * Shared title bar for full-screen settings pages.
 *
 * Layout matches the product spec:
 *  - A back chevron (when [onBack] is set) sits immediately to the LEFT of the
 *    title, on the same line — never above it.
 *  - A close (✕) (when [onClose] is set) sits at the far RIGHT of the title,
 *    where the dashboard avatar used to be.
 *  - An optional [trailing] slot (e.g. "mark all read") renders before the
 *    close button.
 *
 * Pass at most one of [onBack] / [onClose]; the root page uses close, pushed
 * sub-pages use back.
 */
@Composable
fun ScreenTitleBar(
    title: String,
    modifier: Modifier = Modifier,
    onBack: (() -> Unit)? = null,
    onClose: (() -> Unit)? = null,
    titleStyle: TextStyle = BrandText.largeTitle,
    trailing: @Composable (RowScope.() -> Unit)? = null,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (onBack != null) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = null,
                    tint = BrandColor.textPrimary(),
                )
            }
            Spacer(Modifier.width(Spacing.xs))
        }
        Text(
            text = title,
            style = titleStyle,
            color = BrandColor.textPrimary(),
            modifier = Modifier.weight(1f),
        )
        trailing?.invoke(this)
        if (onClose != null) {
            IconButton(onClick = onClose) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = null,
                    tint = BrandColor.textPrimary(),
                )
            }
        }
    }
}
