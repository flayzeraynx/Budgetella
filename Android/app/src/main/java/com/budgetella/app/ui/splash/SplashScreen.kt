package com.budgetella.app.ui.splash

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.budgetella.app.R
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText

/**
 * Compose splash — held by AppRoot while initial auth state resolves. Brief
 * by design; if the user ever sees this for more than ~300 ms something is
 * blocking the splash app-state listener.
 */
@Composable
fun SplashScreen() {
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
                modifier = Modifier.size(120.dp)
            )
            Text(
                text = "Budgetella",
                style = BrandText.title,
                color = BrandColor.textPrimary(),
            )
        }
    }
}
