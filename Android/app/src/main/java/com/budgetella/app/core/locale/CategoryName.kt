package com.budgetella.app.core.locale

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.budgetella.app.R
import com.budgetella.app.data.local.entity.CategoryEntity
import com.budgetella.app.data.model.CategorySlug

/**
 * Display name for a category — looks the slug up in the localized string
 * table so seed categories ported from another locale (e.g. iOS users who
 * created their account on a Turkish device) still render in the current
 * UI language. User-customized categories without a recognized slug fall
 * back to the stored `name` field.
 */
@Composable
@ReadOnlyComposable
fun displayCategoryName(category: CategoryEntity): String {
    val slug = CategorySlug.fromRaw(category.slug)
    val resId = slug?.let { categoryStringRes(it) } ?: 0
    return if (resId != 0) stringResource(resId) else category.name
}

/** Non-composable variant — for places that already have a Context (e.g. notifications). */
fun displayCategoryName(category: CategoryEntity, context: android.content.Context): String {
    val slug = CategorySlug.fromRaw(category.slug)
    val resId = slug?.let { categoryStringRes(it) } ?: 0
    return if (resId != 0) context.getString(resId) else category.name
}

private fun categoryStringRes(slug: CategorySlug): Int = when (slug) {
    CategorySlug.Salary        -> R.string.category_name_salary
    CategorySlug.Freelance     -> R.string.category_name_freelance
    CategorySlug.Investments   -> R.string.category_name_investments
    CategorySlug.Gifts         -> R.string.category_name_gifts
    CategorySlug.ProductSale   -> R.string.category_name_productSale
    CategorySlug.Loan          -> R.string.category_name_loan
    CategorySlug.Food          -> R.string.category_name_food
    CategorySlug.Transportation-> R.string.category_name_transportation
    CategorySlug.Housing       -> R.string.category_name_housing
    CategorySlug.Bills         -> R.string.category_name_bills
    CategorySlug.Healthcare    -> R.string.category_name_healthcare
    CategorySlug.Shopping      -> R.string.category_name_shopping
    CategorySlug.Entertainment -> R.string.category_name_entertainment
    CategorySlug.Education     -> R.string.category_name_education
    CategorySlug.Other         -> R.string.category_name_other
}
