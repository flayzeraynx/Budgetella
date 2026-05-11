package com.budgetella.app.ui.splash

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing

/**
 * Shown by AppRoot between Auth-success and Main while the post-sign-in
 * Firestore fetch is running. Without this hold the user would land on the
 * Main shell while transactions/categories are still being pulled down, and
 * see empty-state copy for the few seconds it takes the fetch to land —
 * which is misleading, especially for users porting their data from iOS.
 */
@Composable
fun SyncingInitialScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor.background()),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Image(
                painter = painterResource(id = R.mipmap.ic_launcher_foreground),
                contentDescription = null,
                modifier = Modifier.size(96.dp)
            )
            Spacer(Modifier.height(Spacing.lg))
            Text(
                text = stringResource(R.string.sync_initial_title),
                style = BrandText.title,
                color = BrandColor.textPrimary(),
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(Spacing.sm))
            Text(
                text = stringResource(R.string.sync_initial_subtitle),
                style = BrandText.body,
                color = BrandColor.textSecondary(),
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(Spacing.xl))
            CircularProgressIndicator(
                modifier = Modifier.size(28.dp),
                strokeWidth = 2.5.dp,
                color = BrandColor.Primary,
            )
        }
    }
}
