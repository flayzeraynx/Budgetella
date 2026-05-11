// Top-level build file — plugin declarations only. App-level config lives in app/build.gradle.kts.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.hilt) apply false
    // Version catalog turns the `google-services` alias' hyphen into a dot for
    // Kotlin DSL access. Writing `libs.plugins.google-services` makes Kotlin
    // parse the minus sign and try `BigDecimal.minus(...)` — hence the sync error.
    alias(libs.plugins.google.services) apply false
}
