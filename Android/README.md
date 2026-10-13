# Budgetella — Android

Native Android client. Full iOS parity (or near it) — see milestone notes below for what's done and what's stubbed.

- **Language**: Kotlin
- **UI**: Jetpack Compose + Material 3
- **Min SDK**: 26 (Android 8.0)
- **Target/Compile SDK**: 36 (Android 16)
- **Application ID**: `com.budgetella.app`
- **Version**: `1.1.4 (10)` — live on Google Play (submitted 2026-10). iOS counterpart: 1.1.1 (3)
- **Toolchain**: AGP 8.13.2 · Gradle 8.14.5 · Kotlin 2.3.21 · KSP 2.3.11 · Hilt 2.58 (pinned, 2.59+ needs AGP 9) · Compose BOM 2026.06.01 (pinned, 1.12 needs AGP 9.1) · Room 2.8.4 · Play Billing 9.1.0
- **AI**: Gemini 2.5 Flash (`data/remote/GeminiChatService.kt`)

The iOS app at `../iOS/` is the source of truth for product design and copy; every Android screen has a Swift counterpart at the same logical path under `../iOS/Budgetella/Features/`.

## Getting started

1. **Open in Android Studio** (Hedgehog or newer). Open the `Android/` folder; Android Studio will run an initial Gradle sync.
2. **Finish the Gradle wrapper.** This repo ships the wrapper scripts but not the `gradle-wrapper.jar` binary. Inside Android Studio open the embedded terminal and run:
   ```
   gradle wrapper --gradle-version 8.14.5
   ```
   …or just sync — Android Studio offers to repair the wrapper on first open.
3. **Drop `google-services.json` into `app/`.** Already configured in Firebase Console; just download and save to `Android/app/google-services.json`.
4. **Set the Gemini key.** Either:
   - Add `GEMINI_API_KEY=...` to `~/.gradle/gradle.properties`, *or*
   - Export `GEMINI_API_KEY` in your shell before invoking Gradle.
5. **Run** the `app` configuration on any API 26+ emulator or device.

## Project layout

```
Android/
├── app/
│   ├── build.gradle.kts                  ← app module config + deps
│   ├── proguard-rules.pro
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── java/com/budgetella/app/
│       │   ├── BudgetellaApplication.kt  ← Firebase init + locale default + DataInitializer seed
│       │   ├── MainActivity.kt           ← FragmentActivity host (Compose root)
│       │   ├── core/
│       │   │   ├── design/               ← port of iOS DesignSystem/
│       │   │   └── locale/LocaleHelper.kt
│       │   ├── data/
│       │   │   ├── auth/                 ← AuthRepository + Firebase impl
│       │   │   ├── backup/               ← JSON export/import (iOS-compatible schema)
│       │   │   ├── local/                ← Room database, DAOs, entities, type converters
│       │   │   ├── model/                ← Enums + Money helper (Long minor-units)
│       │   │   ├── prefs/                ← DataStore wrappers
│       │   │   ├── remote/               ← FirestoreService, FCM service, Gemini chat client
│       │   │   ├── repository/           ← Repository interfaces + Room-backed impls
│       │   │   └── seed/                 ← DataInitializer (default categories + AppSettings)
│       │   ├── di/                       ← Hilt modules
│       │   └── ui/
│       │       ├── AppRoot.kt            ← Splash → Onboarding → Auth → Biometric → Main router
│       │       ├── auth/, biometric/, budgi/, dashboard/, main/, notifications/
│       │       ├── onboarding/, paywall/, settings/, splash/, stats/, transactions/
│       │       └── placeholder/          ← unused (left for reference)
│       └── res/
│           ├── values{,-tr}/strings.xml  ← default English, Turkish override
│           ├── values/{colors,themes}.xml
│           ├── drawable/ic_notification.xml
│           └── mipmap-*/ic_launcher*.png ← from /budgetella-icon/android/
├── gradle/libs.versions.toml             ← version catalog
├── build.gradle.kts                      ← root
├── settings.gradle.kts
└── README.md (this file)
```

77 Kotlin files. Single-module project — multi-module split can come later if compile times stretch.

## Milestone status

### Done

- **M0 — Scaffold** — Gradle, Compose, Hilt, Room, Firebase BOM, Vico, Material3, brand design system port, manifest, splash, app icons.
- **M1 — Data model + persistence** — Room with 7 entities (Transaction, Category, User, AppSettings, Budget, Goal, NotificationRecord). Migration 1→2. Repositories. First-launch seed of 15 default categories + AppSettings row.
- **M2 — Authentication** — Email/password sign-up + sign-in, Google Sign-In via Credential Manager, password reset. Onboarding 3-screen pager. AppRoot router. First-launch English locale.
- **M3 — Transactions CRUD + Firestore sync** — Transactions list (year/month/day grouping), add/edit/delete via ModalBottomSheet, FAB in tab bar. Write-through to Firestore. Pull-on-sign-in via fetchAndSync — your iOS data lands on Android immediately after login.
- **M4 — Dashboard + Stats** — Net balance hero, daily flow line chart (Vico), top categories, recent transactions, AI insight card on the dashboard. Stats donut (Compose Canvas), income/expense toggle, category breakdown rows, MoM delta.
- **M5 — Budgi AI** — Rule-based insight engine port (5 rules), Gemini chat client (now 2.5 Flash), chat UI with user/assistant bubbles + insight cards + typing indicator + first-send consent gate.
- **M6 — Settings** — Gear icon overlay opens a Settings ModalBottomSheet with sections matching iOS: Profile, Premium, Preferences (theme/language/currency pickers), Security (biometric + hide amounts), Data (backup export/import), Notifications (inbox + push toggle), Support, Account (sign out + delete). Biometric lock screen via `androidx.biometric` — AppRoot routes through it when enabled.
- **M7 — Notifications** — `BudgetellaMessagingService` extends `FirebaseMessagingService`. Persists every push as a `NotificationRecord`, posts to system tray, supports deep links. NotificationInboxScreen lists records, marks-read on tap, mark-all-as-read.
- **M8 — Paywall + Play Billing** — DONE (1.0.2). `PlayBillingSubscriptionRepository`, 3 plans (monthly / annually / lifetime), RTDN Cloud Function. See `BILLING.md`.
- **Post-M8 (1.1.x)** — Post-auth walkthrough (Lottie), Rate/Share, voice + camera receipt entry, incremental sync, Settings as full page, About section, targetSdk 36, Kotlin 2.3 toolchain, Gemini 2.5 Flash. See `CHANGELOG.md`.

### Known TODOs / things that need real-world testing

| Item | Why deferred |
|---|---|
| **Apple Sign-In on Android** | Requires Firebase OIDC web flow + Apple Developer Service ID configuration. iOS does it natively. Not blocking for v1 — Google + Email cover the same auth needs. |
| **Glance widget** | The home-screen widget that mirrors iOS WidgetKit is not implemented — Glance has its own setup and the user would need to pin it manually. Tracked as a v1.1 item. |
| **Recurring transactions** | Schema is in place (`isRecurring`, `recurringInterval`, etc.) but no UI for creating or templating recurring transactions yet. |
| **Achievements + Subscription history** | These two entities haven't been added to the Room schema yet (M8.x + M9). |
| **Budget / Goal / Profile Firestore mirror** | `BudgetRepository`, `GoalRepository`, `UserRepository` still have `TODO(M3)` — these only live in Room, so they are lost on reinstall / device change. |
| **Dead code: `SettingsViewModel.deleteAccount()`** | Old best-effort version. Real deletion (re-auth + `user.delete()`) lives in `DeleteAccountViewModel` → `FirebaseAuthRepository.deleteAccount()`; server-side `clearUserDataOnDelete` then wipes subcollections. Safe to remove. |

### Things the user has to do manually (not coding work)

- **Add SHA-1 fingerprints to Firebase Console** — done already per chat.
- **Add `google-services.json` to `Android/app/`** — done already per chat.
- **Set `GEMINI_API_KEY`** in `~/.gradle/gradle.properties` before building. Without it, Budgi chat will return a "API key not configured" error.
- **Test biometric lock on a device** — emulators often lack fingerprint sensors. Toggle it from Settings, kill the app, relaunch.
- **After Play Console upload**, finish Play Billing in `SubscriptionRepository` and add the product IDs.

## Useful commands

```
# Run lint + unit tests
./gradlew :app:lintDebug :app:testDebugUnitTest

# Install debug APK on a connected device
./gradlew :app:installDebug

# Assemble release AAB
./gradlew :app:bundleRelease
```

## Notes

- The app launches in **English** on first install regardless of the device locale — matches the iOS shipped behaviour. The user can switch to Turkish in Settings, which triggers a brief recreate via `AppCompatDelegate.setApplicationLocales`.
- All cross-platform documents (`users/{uid}/transactions`, `users/{uid}/categories`) follow the iOS Firestore schema exactly — same field names, same types (amount as Double major-units, date as Timestamp, enums as raw strings). Adding a transaction on either platform appears on the other within a few seconds.
- The launcher icons under `mipmap-*/` are copies of `/budgetella-icon/android/`. If you update the master SVG, regenerate those folders and re-copy.
- Firebase / Gemini credentials are gitignored. Never check `google-services.json` or `keystore.properties` into the repo.
