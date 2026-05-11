# Budgetella iOS — Claude Notes

**Pure native iOS app.** Swift 6 (strict concurrency) + SwiftUI + SwiftData. Deployment target **iOS 17+** (bazı feature'lar iOS 26+ için gated). Bu, monoreponun en aktif ve production'daki ana projesidir.

> Daha geniş bağlam için `README.md` ve `CHANGELOG.md` dosyalarına bak. Bu CLAUDE.md, README'nin Claude için sıkıştırılmış özetidir.

---

## Hızlı Başlangıç

Proje **XcodeGen** ile yönetilir — `Budgetella.xcodeproj` build artifact'tir, doğrudan düzenleme. Asıl konfigürasyon `project.yml` dosyasındadır.

```bash
brew install xcodegen          # bir kerelik
cd /Users/flayzeraynx/Development/Budgetella/iOS
xcodegen generate              # project.yml'den .xcodeproj üret
open Budgetella.xcodeproj
```

Build / test / archive `xcodebuild` ile (komutlar `README.md`'de). Scheme: `Budgetella`.

---

## Olmazsa Olmaz Konfigürasyon

İki dosya **gitignored** — bunlar olmadan derlenmez:

1. `Budgetella/Resources/GoogleService-Info.plist` — Firebase Console → `budgetella-d1d41` projesi → iOS app (bundle `com.ozankilic.budgetella`).
2. `Budgetella/Configuration/Secrets.xcconfig` — `GEMINI_API_KEY = ...` (Google AI Studio'dan).

`Info.plist` `$(GEMINI_API_KEY)` referansını okur ve `GeminiInsightService` runtime'da bunu kullanır. **`ANTHROPIC_API_KEY` client'ta tutulmaz**, Cloud Function proxy v1.1'de gelecek.

---

## Mimari Özet

```
Budgetella/
├── BudgetellaApp.swift       @main — SwiftData ModelContainer + Firebase init
├── ContentView.swift         Auth/onboarding/main routing
├── Core/
│   ├── Models/               9 @Model: Transaction, Category, Budget, Goal,
│   │                         Achievement, User, AppSettings, SubscriptionRecord,
│   │                         NotificationRecord
│   ├── Services/             AuthService, FirestoreService, SubscriptionService,
│   │                         NotificationService, KeychainHelper,
│   │                         BackupExportService, BackupImportService,
│   │                         GeminiInsightService
│   ├── AI/                   KeywordCategorizer (TR keyword fallback)
│   ├── Helpers/              AppDelegate, LocaleHelper
│   ├── Intents/              AddTransactionIntent + Siri shortcuts
│   └── Widget/               WidgetDataManager (shared with extension)
├── DesignSystem/             Colors, Typography, Spacing, BrandAlert,
│                             ShimmerModifier, BudgetellaLogoView, EnvironmentKeys
├── Features/
│   ├── Auth/                 Welcome, SignIn, SignUp, ForgotPassword, OTP,
│   │                         FaceIDSetup, FaceIDLock
│   ├── Dashboard/            DashboardView + ViewModel + Cards
│   ├── Transactions/         List + EditTransactionSheet
│   ├── QuickEntry/           Voice, Camera (OCR), Manual
│   ├── Settings/             Profile, Categories, Subscription, Notifications,
│   │                         Support (WebView), DeleteAccount, NotificationSettings
│   ├── Stats/                StatsView + BudgiView (AI insights UI)
│   ├── Onboarding/           4-step + backup import
│   ├── Paywall/              StoreKit 2 paywall
│   ├── Navigation/           MainTabView
│   ├── Notifications/        Inbox
│   └── Insights/             v1.1 — şu an boş
├── Configuration/            xcconfig dosyaları
└── Resources/                Assets.xcassets, Localizable.xcstrings (TR/EN)

BudgetellaWidgetExtension/    Home screen widget (ayrı target)
BudgetellaTests/              XCTest — v1.1'de doldurulacak
BudgetellaUITests/            XCUITest — v1.1'de doldurulacak
```

---

## Stack Tablosu

| Katman | Teknoloji |
|---|---|
| Dil | Swift 6, strict concurrency mode |
| UI | SwiftUI, Swift Charts, NavigationStack |
| Persistence | SwiftData (local) + Firestore (premium sync) + Keychain (auth token) |
| Auth | FirebaseAuth + Sign in with Apple + GoogleSignIn-iOS + Face ID/Touch ID |
| IAP | **StoreKit 2 native** — RevenueCat KULLANILMIYOR |
| AI insights | Gemini 2.0 Flash (`GeminiInsightService`, günlük cache) |
| AI OCR | VisionKit + Vision + FoundationModels (iOS 26+ gated) |
| AI kategori | Local TR keyword fallback (`KeywordCategorizer`) |
| Background | BGTaskScheduler |
| Push | UserNotifications + Firebase Cloud Messaging |
| Widget | WidgetKit (BudgetellaWidgetExtension target) |
| Shortcuts | App Intents (AddTransactionIntent) |
| Analytics | Firebase Analytics |
| Test | XCTest + XCUITest (kapsam v1.1) |

SwiftPM bağımlılıkları `project.yml` içinde:
- `firebase-ios-sdk` ≥ 11.0.0 (Auth, Firestore, Messaging — Analytics dahil)
- `GoogleSignIn-iOS` ≥ 8.0.0

---

## Bundle / Sürüm Bilgisi

- **Bundle ID:** `com.ozankilic.budgetella`
- **Development Team:** `ZS9KW29SGF`
- **V1 dağıtım:** Türkiye-only, iPhone-only
- **Fiyatlama:** $4.99/ay + $39.99/yıl + 7 gün free trial; ₺TL için ayrı tier
- **iPad:** v1.1'e ertelendi

Sürüm/build sayıları için her zaman `CHANGELOG.md`'yi referans al — README'dekiler eski olabilir.

---

## Ozzy'nin Verisi

Ozzy'nin 4 yıllık webapp verisi `~/Downloads/budgetella_backup_2026-05-01.json` dosyasında. Onboarding'in "Yedeğimi içe aktar" adımı `BackupImportService` üzerinden yükler. Dexie → SwiftData @Model dönüşüm mantığı bu servisin içindedir.

---

## Sık Karşılaşılan Görevler — Nereye Bak?

- **Yeni feature ekleme** → `Features/<Alan>/` altına yeni klasör, model değişikliği gerekiyorsa `Core/Models/` + Firestore sync güncellemesi `FirestoreService.swift`.
- **Yeni renk/tipografi** → `DesignSystem/` — hard-code değer KULLANMA.
- **Yeni dil string'i** → `Resources/Localizable.xcstrings` (TR + EN birlikte).
- **Push debug** → Kök dizindeki `send-test-push.js` (UID'i kendi token'ınla değiştir).
- **StoreKit / abonelik** → `Core/Services/SubscriptionService.swift` (web ödemesi için Stripe ayrı: `budgetella_functions/`).
- **Gemini insights** → `Core/Services/GeminiInsightService.swift`.
- **Push notification handler** → `Core/Helpers/AppDelegate.swift`.

---

## Referans Projeler (Ozzy'nin diğer projeleri)

- **TealSky** — WebView + native bridges + FCM push pattern
- **Reelight** — freemium pattern + App Store submission akışı
- **Kelimoji** — TR-only launch + StoreKit 2 pricing matrix

---

## v1.1 Backlog (Tamamlanmamış)

- `Features/Insights/` doldur — Budgi AI chat asistanı (altyapı `BudgiView`'da hazır)
- XCTest / XCUITest coverage
- Claude API receipt OCR (Cloud Function proxy zorunlu — key client'ta tutulmayacak)
- iPad layout
- EUR/GBP/JPY currency desteği
- Voice Input UI (altyapı V1'de hazır, sadece UI eksik)
