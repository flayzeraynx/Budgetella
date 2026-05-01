# Budgetella iOS

Pure native iOS app — **Swift 6 + SwiftUI + SwiftData**. Deployment target **iOS 17+** (FoundationModels iOS 26+ optional gated).

> **Status:** Faz 1 (build skeleton) — 2026-05-01 itibarıyla klasör iskeleti + project.yml + Models hazırlanıyor. Tasarım onayı sonrası Faz 3 (Auth) ve Faz 4 (Features) açılacak.

---

## Kurulum

1. **XcodeGen kur** (manuel `.xcodeproj` git'lemiyoruz — declarative tutuyoruz):
   ```bash
   brew install xcodegen
   ```

2. **Xcode projesini üret:**
   ```bash
   cd /Users/flayzeraynx/Development/Budgetella/iOS
   xcodegen generate
   ```

3. **Apple Developer Team ID set et** — `project.yml` içinde `DEVELOPMENT_TEAM` dolduruldu sonra tekrar:
   ```bash
   xcodegen generate
   ```

4. **Aç:**
   ```bash
   open Budgetella.xcodeproj
   ```

5. **Firebase config** — Mevcut `budgetella-d1d41` projesine iOS app ekle (Firebase Console → Add iOS app → Bundle ID `com.toprakkilic.budgetella`), `GoogleService-Info.plist`'i indir, `Budgetella/Resources/`'a koy. **Asla commitleme** (gitignored).

---

## Mimari

```
Budgetella/
├── BudgetellaApp.swift           App entry — SwiftData ModelContainer init
├── ContentView.swift             Placeholder; tasarım sonrası MainTabView
├── Core/                         Domain + business logic (UI'dan bağımsız)
│   ├── Models/                   SwiftData @Model classes
│   ├── Persistence/              ModelContainer + Firestore mirror
│   ├── AI/                       Categorizer, Receipt OCR, Insights
│   └── Services/                 Auth, Subscription, Background tasks
├── DesignSystem/                 Colors, Typography, Spacing tokens (tasarım sonrası)
├── Features/                     UI ekranları
│   ├── Onboarding/
│   ├── Dashboard/
│   ├── Transactions/
│   ├── Settings/
│   ├── Insights/
│   └── Paywall/
└── Resources/                    Assets.xcassets, Localizable.xcstrings, Info.plist
```

---

## Stack

| Katman | Teknoloji |
|---|---|
| Dil | Swift 6 (`swift-concurrency-6-2` skill aktif) |
| UI | SwiftUI, Swift Charts, NavigationStack |
| Persistence | SwiftData (local) + Firestore (sync, premium tier) + Keychain (auth token) |
| Auth | FirebaseAuth + AuthenticationServices (Sign in with Apple) + GoogleSignIn + LocalAuthentication (Face ID/Touch ID) |
| IAP | StoreKit 2 + RevenueCat |
| AI | VisionKit + Vision + FoundationModels (iOS 26+) + Anthropic API (Claude Sonnet 4.6 + Haiku 4.5) |
| Background | BGTaskScheduler |
| Push | UserNotifications + Firebase Cloud Messaging |
| Test | XCTest + XCUITest, hedef coverage 60%+ |

---

## Bundle Configuration

- **Bundle ID:** `com.toprakkilic.budgetella`
- **Marketing version:** 1.0.0
- **Türkiye-only V1** (App Store availability — Kelimoji pattern)
- **Pricing:** $4.99/ay + $39.99/yıl + 7 gün free trial. Türkiye için ayrı ₺TL tier.
- **iPhone only V1** (iPad V1.1'e ertelendi)

---

## Required Secrets

`.env`'de tutulmaz — Xcode build settings veya `.xcconfig` ile inject:

- `ANTHROPIC_API_KEY` — **Asla client'ta tutma**, Cloud Function proxy üzerinden
- `REVENUECAT_API_KEY` — RevenueCat dashboard'dan
- `GoogleService-Info.plist` — Firebase Console'dan, gitignored

---

## Build & Run

```bash
# Generate
xcodegen generate

# Build
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
```

---

## Mevcut Webapp Verisi Import

Ozzy'nin 4 yıllık verisi `~/Downloads/budgetella_backup_2026-05-01.json`'da. Onboarding'de "Yedek dosyamı içe aktar" adımı ile yüklenecek. Translation layer Faz 2'de yazılacak (Webapp Dexie schema → SwiftData @Model mapping; UUID generation + Date parsing + type translation).

---

## Status & Roadmap

- [x] Klasör iskeleti (2026-05-01)
- [ ] XcodeGen `project.yml` ✅
- [ ] `.gitignore` ✅
- [ ] `BudgetellaApp.swift` + `ContentView.swift`
- [ ] Core/Models — SwiftData @Model classes
- [ ] Core/AI — KeywordCategorizer (Türkçe sözlük)
- [ ] Resources/Localizable.xcstrings — TR/EN/DE
- [ ] Firebase iOS SDK entegrasyonu (SPM)
- [ ] AuthService — email/password + Apple + Google + biometric
- [ ] RevenueCat entegrasyonu
- [ ] **TASARIM ONAYI** ← burada bekliyoruz
- [ ] Features (Dashboard, Transactions, Settings, Insights, Paywall)
- [ ] AI (Receipt OCR + Spending Insights)
- [ ] XCTest + XCUITest
- [ ] App Store Connect setup
- [ ] TestFlight beta
- [ ] Public TR launch

Detay plan: `~/.claude/plans/su-anda-secili-projeyi-hidden-gizmo.md`

---

## Önceki Projelerden Referans

- **TealSky** (yayında, App Store + Play Store) — WebView + native bridges hybrid
- **Reelight** (yayında, App Store + Play Store) — freemium pattern
- **Kelimoji** (V1 Türkiye-only) — pricing & availability matrisi

Budgetella, **Reelight'ın freemium pattern'i** + **Kelimoji'nin TR-only launch yaklaşımı** ile birleşiyor.
