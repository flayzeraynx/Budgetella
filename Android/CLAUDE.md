# Budgetella Android — Claude Notes

**Native Android port.** Kotlin + Jetpack Compose + Hilt + Room + Firebase.

> **Durum: SADECE İSKELET.** Gradle config, version catalog ve dependency tanımları yerinde — fakat `app/src/` altında henüz Kotlin kaynak kod YOK. İlk gerçek aktivite/ekran eklenmesi bekleniyor. iOS uygulamasıyla **feature paritesi** hedeflenir.

---

## Yapı

```
Android/
├── build.gradle.kts            Root — Android Gradle Plugin, Kotlin, Hilt, KSP, GMS plugins
├── settings.gradle.kts         pluginManagement + :app include
├── gradle.properties           JDK 17, parallel build, build cache, configuration cache on
├── gradle/
│   ├── libs.versions.toml      Version catalog (TÜM bağımlılıklar burada — tek doğruluk kaynağı)
│   └── wrapper/
│       └── gradle-wrapper.properties   (wrapper jar henüz commit edilmemiş)
└── app/
    ├── build.gradle.kts        App modülü — dependencies, buildConfig, signing
    ├── proguard-rules.pro
    └── (src/ henüz yok)
```

---

## Build

JDK 17 zorunlu. `compileSdk 35`, `minSdk 26`, `targetSdk 35`.

```bash
cd /Users/flayzeraynx/Development/Budgetella/Android
./gradlew assembleDebug         # debug APK
./gradlew installDebug          # bağlı cihaza yükle
./gradlew clean
```

> `gradle-wrapper.jar` repo'da yoksa `gradle wrapper` ile üretmen gerekir.

---

## Bundle / Sürüm

- **applicationId:** `com.budgetella.app`
- **versionCode:** 2
- **versionName:** 1.0.1
- iOS ile parite hedefi: TR-only V1, sonra global.

---

## Gizli Anahtarlar

`GEMINI_API_KEY` build sırasında `~/.gradle/gradle.properties` veya env değişkeninden okunur ve `buildConfigField` üzerinden `BuildConfig.GEMINI_API_KEY` olarak inject edilir. **Repoda commit etme.**

Firebase için `app/google-services.json` (gitignored) — Firebase Console → `budgetella-d1d41` projesi → Android app (`com.budgetella.app`).

---

## Planlanan Stack (libs.versions.toml'dan)

| Katman | Kütüphane |
|---|---|
| UI | Jetpack Compose (BOM), Material 3, Compose Navigation |
| DI | Hilt + Hilt Compose Navigation |
| Persistence | Room (KSP) + DataStore Preferences |
| Auth | Firebase Auth + Credential Manager (Google Sign-In) |
| Backend | Firebase BOM (Auth, Firestore, Messaging, Analytics, Crashlytics) |
| Network | Ktor client (Gemini için) + kotlinx.serialization |
| Görüntü | Coil 3 |
| Grafik | Vico (charts) |
| Biometric | AndroidX Biometric |
| Splash | AndroidX SplashScreen |

> **Mimari hedef (iOS ile parite):**
> - iOS `Core/Models/` → Room `@Entity`'ler
> - iOS `Core/Services/` → Kotlin `*Service` sınıfları (Hilt @Singleton)
> - iOS `Features/<Alan>/` → Compose ekranları + ViewModel + State
> - iOS `DesignSystem/` → Compose theme (Color.kt, Typography.kt, Spacing.kt)

---

## Yapılması Gerekenler (Sıralı)

1. `gradle-wrapper.jar` commit et — `gradle wrapper --gradle-version 8.x`
2. `app/src/main/AndroidManifest.xml` oluştur
3. `app/src/main/java/com/budgetella/app/` paket yapısı — `core/`, `features/`, `ui/theme/`
4. `BudgetellaApplication.kt` — `@HiltAndroidApp`, Firebase init
5. iOS `Core/Models/` listesini Room `@Entity`'lere çevir
6. iOS feature parite sırası: Auth → Onboarding → Dashboard → Transactions → QuickEntry → Settings → Stats → Paywall

---

## Cross-Cutting

- Firebase proje: `budgetella-d1d41` (iOS ile paylaşımlı)
- Cloud Functions endpoint'leri `budgetella_functions/` altında — Stripe IAP web için ama Android Play Billing kendi içinde yürütür
- Premium fiyat iOS ile aynı: $4.99/ay + $39.99/yıl
