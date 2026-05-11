package com.budgetella.app.ui.main

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Home
import androidx.compose.ui.graphics.vector.ImageVector
import com.budgetella.app.R

/** 4-tab layout — matches iOS AppTab enum (home / list / stats / ai). */
enum class AppTab(
    @StringRes val labelRes: Int,
    val icon: ImageVector
) {
    Home(R.string.tab_home,  Icons.Filled.Home),
    List(R.string.tab_list,  Icons.AutoMirrored.Filled.List),
    Stats(R.string.tab_stats, Icons.Filled.BarChart),
    Ai(R.string.tab_ai,       Icons.Filled.AutoAwesome);

    companion object {
        val ordered: List<AppTab> = entries.toList()
    }
}
