package com.budgetella.app.data.model

/**
 * Kotlin ports of the iOS domain enums. The `raw` value of each entry MUST match
 * the Swift `rawValue` exactly so Firestore documents written by either app
 * round-trip cleanly. Don't rename a case without bumping a Firestore migration.
 */

// ── Transaction ────────────────────────────────────────────────────────────

enum class TransactionType(val raw: String) {
    Income("income"),
    Expense("expense");

    companion object {
        fun fromRaw(raw: String?): TransactionType =
            entries.firstOrNull { it.raw == raw } ?: Expense
    }
}

enum class TransactionStatus(val raw: String) {
    Completed("completed"),
    Pending("pending"),
    Planned("planned");

    companion object {
        fun fromRaw(raw: String?): TransactionStatus =
            entries.firstOrNull { it.raw == raw } ?: Completed
    }
}

enum class RecurringInterval(val raw: String) {
    Daily("daily"),
    Weekly("weekly"),
    Monthly("monthly"),
    Yearly("yearly");

    companion object {
        fun fromRaw(raw: String?): RecurringInterval? =
            entries.firstOrNull { it.raw == raw }
    }
}

// ── Category ───────────────────────────────────────────────────────────────

/**
 * 15 default categories seeded on first launch. Custom categories (premium)
 * have `slug = null` and use the user-entered name as-is.
 *
 * Defaults below mirror iOS CategorySlug.swift one-for-one — same icon, same
 * colour, same sort order. The icon names are SF Symbols on iOS; on Android
 * they're mapped to Material Icons via a separate `slug.materialIcon()`
 * extension that lives in the UI layer (added when the dashboard ships).
 */
enum class CategorySlug(
    val raw: String,
    val type: TransactionType,
    val defaultIcon: String,
    val defaultColorHex: String,
    val turkishName: String,
) {
    // Income
    Salary       ("salary",       TransactionType.Income,  "banknote",                       "#22c55e", "Maaş"),
    Freelance    ("freelance",    TransactionType.Income,  "briefcase",                      "#10b981", "Freelance"),
    Investments  ("investments",  TransactionType.Income,  "chart.line.uptrend.xyaxis",      "#06b6d4", "Yatırım"),
    Gifts        ("gifts",        TransactionType.Income,  "gift",                           "#ec4899", "Hediyeler"),
    ProductSale  ("productSale",  TransactionType.Income,  "shippingbox.fill",               "#f59e0b", "Ürün Satışı"),
    Loan         ("loan",         TransactionType.Income,  "arrow.left.arrow.right.circle.fill", "#8b5cf6", "Borç Para"),

    // Expense
    Food         ("food",         TransactionType.Expense, "fork.knife",                     "#f59e0b", "Yiyecek"),
    Transportation("transportation", TransactionType.Expense, "car.fill",                    "#3b82f6", "Ulaşım"),
    Housing      ("housing",      TransactionType.Expense, "house.fill",                     "#8b5cf6", "Konut"),
    Bills        ("bills",        TransactionType.Expense, "doc.text",                       "#ef4444", "Faturalar"),
    Healthcare   ("healthcare",   TransactionType.Expense, "cross.case",                     "#dc2626", "Sağlık"),
    Shopping     ("shopping",     TransactionType.Expense, "bag.fill",                       "#a855f7", "Alışveriş"),
    Entertainment("entertainment",TransactionType.Expense, "tv",                             "#f43f5e", "Eğlence"),
    Education    ("education",    TransactionType.Expense, "book.fill",                      "#0ea5e9", "Eğitim"),
    Other        ("other",        TransactionType.Expense, "tag",                            "#94a3b8", "Diğer");

    companion object {
        fun fromRaw(raw: String?): CategorySlug? =
            entries.firstOrNull { it.raw == raw }
    }
}

// ── User / Subscription ─────────────────────────────────────────────────────

enum class SubscriptionType(val raw: String) {
    None("none"),
    Monthly("monthly"),
    Yearly("yearly"),
    Lifetime("lifetime");

    companion object {
        fun fromRaw(raw: String?): SubscriptionType =
            entries.firstOrNull { it.raw == raw } ?: None
    }
}

// ── App preferences ────────────────────────────────────────────────────────

enum class AppCurrency(val raw: String, val symbol: String) {
    Try("TRY", "₺"),
    Usd("USD", "$"),
    Eur("EUR", "€"),
    Gbp("GBP", "£");

    companion object {
        fun fromRaw(raw: String?): AppCurrency =
            entries.firstOrNull { it.raw == raw } ?: Try
    }
}

enum class AppLanguage(val raw: String, val displayName: String, val flagEmoji: String) {
    Turkish("tr", "Türkçe",  "🇹🇷"),
    English("en", "English", "🇺🇸"),
    German ("de", "Deutsch", "🇩🇪");   // Hidden in V1 UI

    companion object {
        /** Languages shown in V1 picker (German is V2). Mirrors iOS AppLanguage.v1Cases. */
        val v1Cases: List<AppLanguage> = listOf(English, Turkish)

        fun fromRaw(raw: String?): AppLanguage =
            entries.firstOrNull { it.raw.equals(raw, ignoreCase = true) } ?: English
    }
}

enum class AppTheme(val raw: String) {
    Light("light"),
    Dark("dark"),
    System("system");

    companion object {
        fun fromRaw(raw: String?): AppTheme =
            entries.firstOrNull { it.raw == raw } ?: Dark   // iOS defaults to dark
    }
}

// ── Goal ───────────────────────────────────────────────────────────────────

enum class GoalTemplate(val raw: String) {
    EmergencyFund("emergency_fund"),
    Vacation("vacation"),
    Education("education"),
    Technology("technology"),
    Vehicle("vehicle"),
    Home("home"),
    Custom("custom");

    companion object {
        fun fromRaw(raw: String?): GoalTemplate? =
            entries.firstOrNull { it.raw == raw }
    }
}
