# Budgetella iOS

Pure native iOS app — **Swift 6 + SwiftUI + SwiftData**. Deployment target **iOS 17+** (FoundationModels iOS 26+ optional gated).

> **Status:** v1.0.0 (build 15) — App Store review'a gönderildi. Son commit: 2026-05-06 "IOS final build".

---

## Kurulum

1. **XcodeGen kur:**
   ```bash
   brew install xcodegen
   ```

2. **Xcode projesini üret:**
   ```bash
   cd /Users/flayzeraynx/Development/Budgetella/iOS
   xcodegen generate
   ```

3. **Aç:**
   ```bash
   open Budgetella.xcodeproj
   ```

4. **Firebase config** — `budgetella-d1d41` projesinden iOS bundle `com.ozankilic.budgetella` için `GoogleService-Info.plist`'i indir, `Budgetella/Resources/`'a koy. Asla commit'leme (gitignored).

5. **Secrets** — `Budgetella/Configuration/Secrets.xcconfig` dosyasını oluştur (gitignored):
   ```
   GEMINI_API_KEY = ...
   ```

---

## Mimari

```
iOS/
├── Budgetella/
│   ├── BudgetellaApp.swift           App entry — SwiftData ModelContainer + Firebase init
│   ├── ContentView.swift             Auth/onboarding/main routing
│   ├── Core/
│   │   ├── Models/                   SwiftData @Model: Transaction, Category, Budget, Goal,
│   │   │                             Achievement, User, AppSettings, SubscriptionRecord,
│   │   │                             NotificationRecord
│   │   ├── Persistence/              ModelContainer + Firestore sync
│   │   ├── AI/                       KeywordCategorizer (TR keyword fallback)
│   │   ├── Services/                 AuthService, FirestoreService, SubscriptionService,
│   │   │                             NotificationService, KeychainHelper,
│   │   │                             BackupExportService, BackupImportService,
│   │   │                             GeminiInsightService
│   │   ├── Helpers/                  AppDelegate, LocaleHelper
│   │   ├── Intents/                  AddTransactionIntent, BudgetellaShortcuts (Siri)
│   │   └── Widget/                   WidgetDataManager
│   ├── DesignSystem/                 Colors, Typography, Spacing, BrandAlert,
│   │                                 ShimmerModifier, BudgetellaLogoView, EnvironmentKeys
│   ├── Features/
│   │   ├── Auth/                     Welcome, SignIn, SignUp, ForgotPassword, OTP,
│   │   │                             FaceIDSetup, FaceIDLock + components
│   │   ├── Dashboard/                DashboardView, DashboardViewModel, DashboardCards
│   │   ├── Transactions/             TransactionsView, EditTransactionSheet
│   │   ├── QuickEntry/               VoiceEntry, CameraEntry (OCR), ManualEntry
│   │   ├── Settings/                 SettingsView, ProfileView, CategoryManagement,
│   │   │                             SubscriptionView, PickerSheets, DeleteAccount,
│   │   │                             NotificationSettings, SupportWebView
│   │   ├── Stats/                    StatsView, BudgiView (AI insights UI)
│   │   ├── Onboarding/               OnboardingView, WelcomeView, OnboardingHelpers
│   │   ├── Paywall/                  PaywallView
│   │   ├── Navigation/               MainTabView
│   │   ├── Notifications/            NotificationsInboxView
│   │   └── Insights/                 (V1.1)
│   ├── Configuration/                Secrets.xcconfig (gitignored)
│   └── Resources/                    Assets.xcassets, Localizable.xcstrings (TR/EN)
├── BudgetellaWidgetExtension/        Home screen widget
├── BudgetellaTests/
└── BudgetellaUITests/
```

---

## Stack

| Katman | Teknoloji |
|---|---|
| Dil | Swift 6, strict concurrency |
| UI | SwiftUI, Swift Charts, NavigationStack |
| Persistence | SwiftData (local) + Firestore (sync, premium) + Keychain (auth token) |
| Auth | FirebaseAuth + Sign in with Apple + GoogleSignIn + Face ID/Touch ID |
| IAP | **StoreKit 2 native** (RevenueCat yok) |
| AI — Insights | Gemini 2.0 Flash (GeminiInsightService, günlük cache) |
| AI — OCR | VisionKit + Vision + FoundationModels (iOS 26+ gated) |
| AI — Kategori | Local TR keyword fallback (KeywordCategorizer) |
| Background | BGTaskScheduler |
| Push | UserNotifications + Firebase Cloud Messaging |
| Widget | WidgetKit (BudgetellaWidgetExtension) |
| Shortcuts | App Intents (AddTransactionIntent) |
| Analytics | Firebase Analytics |
| Test | XCTest + XCUITest |

---

## Bundle Configuration

- **Bundle ID:** `com.ozankilic.budgetella`
- **Marketing version:** 1.0.0 / Build 15
- **Türkiye-only V1** (App Store availability)
- **Pricing:** $4.99/ay + $39.99/yıl + 7 gün free trial; ayrı ₺TL tier
- **iPhone only V1** (iPad V1.1'e ertelendi)
- **Development Team:** ZS9KW29SGF

---

## Required Secrets

`.env`'de tutulmaz — `Secrets.xcconfig` ile inject (gitignored):

- `GEMINI_API_KEY` — Google AI Studio'dan; insight servisi için
- `GoogleService-Info.plist` — Firebase Console'dan, gitignored
- Face ID token → Keychain'de persist, kaynak kodda yok

> `ANTHROPIC_API_KEY` client'ta **asla** tutulmuyor. OCR/kategori için Cloud Function proxy planlandı (V1.1).

---

## Build & Run

```bash
# Generate xcodeproj
xcodegen generate

# Build (simulator)
xcodebuild -project Budgetella.xcodeproj \
  -scheme Budgetella \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# Test
xcodebuild test \
  -project Budgetella.xcodeproj \
  -scheme Budgetella \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -enableCodeCoverage YES

# Archive (distribution)
xcodebuild archive \
  -project Budgetella.xcodeproj \
  -scheme Budgetella \
  -configuration Release \
  -archivePath build/Budgetella.xcarchive
```

---

## Mevcut Webapp Verisi Import

Ozzy'nin 4 yıllık verisi `~/Downloads/budgetella_backup_2026-05-01.json`'da. Onboarding'de "Yedek dosyamı içe aktar" adımı (`BackupImportService`) ile yükleniyor. Webapp Dexie schema → SwiftData @Model mapping dahil.

---

## Status & Roadmap

### v1.0 — Tamamlandı (2026-05-01 → 2026-05-06)
- [x] XcodeGen project.yml, Swift 6 strict concurrency
- [x] Core/Models — 9 SwiftData @Model class
- [x] Core/Services — Auth, Firestore, Subscription (StoreKit 2), Notification, Keychain, Backup
- [x] Core/AI — KeywordCategorizer (TR), GeminiInsightService
- [x] Design System — Colors, Typography, Spacing, BrandAlert, Shimmer
- [x] Auth flow — Welcome, SignIn, SignUp, ForgotPassword, OTP, Face ID setup/lock
- [x] Onboarding (4 adım, backup import dahil)
- [x] Dashboard + Cards
- [x] Transactions (list + edit)
- [x] QuickEntry — Manual, Voice, Camera OCR
- [x] Settings — Profile, Category mgmt, Subscription, Notifications, Support, Delete account
- [x] Stats + BudgiView (Gemini insights UI)
- [x] Paywall (StoreKit 2, $4.99/ay + $39.99/yıl + $99.99 lifetime)
- [x] Push notifications (FCM)
- [x] Widget Extension (home screen)
- [x] Siri Shortcuts (AddTransactionIntent)
- [x] Firebase Analytics
- [x] Localizable.xcstrings (TR/EN)
- [x] TestFlight beta yayını
- [x] App Store review'a gönderildi

### v1.1 — Planlanan
- [ ] Insights feature (klasör hazır, içerik yok)
- [ ] XCTest / XCUITest coverage
- [ ] Claude API receipt OCR (Cloud Function proxy)
- [ ] iPad desteği
- [ ] EUR/GBP/JPY currency desteği
- [ ] Budgi AI chat asistanı (BudgiView altyapısı hazır)
- [ ] Voice Input UI (altyapı V1'de hazır)

---

## Referans Projeler

- **TealSky** — WebView + native bridges, FCM push pattern
- **Reelight** — freemium pattern, App Store submission akışı
- **Kelimoji** — TR-only launch, StoreKit 2 + pricing matrix
