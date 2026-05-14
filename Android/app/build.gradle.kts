import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
    alias(libs.plugins.google.services)
}

android {
    namespace = "com.budgetella.app"
    compileSdk = 35

    // Release signing — reads credentials from `keystore.properties` at the repo root.
    // That file is gitignored; CI populates it from secrets at build time.
    // On a fresh clone without keystore.properties the block is skipped, so debug
    // builds still work without any signing setup.
    val keystorePropsFile = rootProject.file("keystore.properties")
    val keystoreProps = Properties().apply {
        if (keystorePropsFile.exists()) load(keystorePropsFile.inputStream())
    }

    signingConfigs {
        create("release") {
            if (keystorePropsFile.exists()) {
                storeFile = rootProject.file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.budgetella.app"
        minSdk = 26          // Android 8.0 — Compose-friendly + adaptive icons + biometric
        targetSdk = 35
        versionCode = 4      // 1.0.3 — Google Sign-In SHA-1 fix (new OAuth clients)
        versionName = "1.0.3"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables { useSupportLibrary = true }

        // Limit native libs to 64-bit ABIs only.
        // • Eliminates the "16 KB alignment" warning from legacy armeabi-v7a / x86 .so files
        //   (those architectures don't even support 16 KB pages — the warning is spurious).
        // • Reduces APK size. All Android 8+ devices that matter ship 64-bit CPUs.
        ndk { abiFilters += listOf("arm64-v8a", "x86_64") }

        // Read the Gemini API key from local properties or env at build time.
        // Equivalent to the iOS Secrets.xcconfig flow.
        val geminiKey: String = providers
            .gradleProperty("GEMINI_API_KEY")
            .getOrElse(System.getenv("GEMINI_API_KEY") ?: "")
        buildConfigField("String", "GEMINI_API_KEY", "\"$geminiKey\"")
    }

    buildTypes {
        debug {
            // No applicationIdSuffix so debug builds match the Firebase-registered
            // package name `com.budgetella.app` (single google-services.json entry).
            // If you ever want debug + release side-by-side on the same device, add
            // `com.budgetella.app.debug` as a second Android app in Firebase Console
            // and re-add the suffix here.
            versionNameSuffix = "-dev"
            isMinifyEnabled = false
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Signing credentials are loaded from `keystore.properties` at the repo
            // root (see the signingConfigs block above). On a fresh clone without
            // that file, the release config is empty — `bundleRelease` will fail
            // with a clear "no signing config" error, which is the desired guard.
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-opt-in=kotlin.RequiresOptIn",
            "-opt-in=androidx.compose.material3.ExperimentalMaterial3Api",
            "-opt-in=androidx.compose.foundation.ExperimentalFoundationApi",
            "-opt-in=kotlinx.coroutines.ExperimentalCoroutinesApi"
        )
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        jniLibs {
            // Store .so files uncompressed so the OS can map them directly
            // at the correct 16 KB page-size boundary (Android 15+ requirement).
            useLegacyPackaging = false
        }
    }
}

// Room schema export — `exportSchema = true` on @Database writes JSON snapshots
// here, one per version. They ship in the repo so future migrations can diff.
ksp {
    arg("room.schemaLocation", "$projectDir/schemas")
    arg("room.incremental", "true")
}

dependencies {
    // AndroidX core
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    // Provides the XML `Theme.Material3.*` parent styles used by themes.xml
    // (Compose handles in-app theming itself, but the Activity window theme
    // still resolves at the XML layer.)
    implementation(libs.google.android.material)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.splashscreen)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.biometric)

    // Compose
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.compose.foundation)
    implementation(libs.androidx.compose.animation)
    implementation(libs.androidx.compose.ui.tooling.preview)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)

    // Hilt
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    // Room
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)

    // Firebase
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.auth.ktx)
    implementation(libs.firebase.firestore.ktx)
    implementation(libs.firebase.messaging.ktx)
    implementation(libs.firebase.analytics.ktx)
    // Crashlytics requires the `com.google.firebase.crashlytics` Gradle plugin
    // (which injects a build ID into the APK). Deferring until we wire up the
    // mapping-file upload flow — keep the dep commented out so the artifact
    // is not pulled in and the app starts without a build-ID assertion.
    // implementation(libs.firebase.crashlytics.ktx)

    // Google Sign-In via Credential Manager (replaces deprecated GoogleSignInClient)
    implementation(libs.androidx.credentials)
    implementation(libs.androidx.credentials.play.services)
    implementation(libs.google.id)

    // Coroutines (.await() on Firebase Tasks lives in -play-services)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.coroutines.play.services)

    // Networking + serialisation (Gemini / Firestore custom calls)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.ktor.client.core)
    implementation(libs.ktor.client.okhttp)
    implementation(libs.ktor.client.content.negotiation)
    implementation(libs.ktor.serialization.kotlinx.json)

    // Image loading
    implementation(libs.coil.compose)

    // Charts
    implementation(libs.vico.compose)

    // CameraX — camera viewfinder + image capture for receipt scanning
    implementation(libs.camerax.camera2)
    implementation(libs.camerax.lifecycle)
    implementation(libs.camerax.view)

    // ML Kit Text Recognition — receipt OCR
    implementation(libs.mlkit.text.recognition)

    // Google Play Billing — premium subscriptions + lifetime IAP (iOS StoreKit 2 parity)
    implementation(libs.play.billing.ktx)

    // Test
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit.ext)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
}
