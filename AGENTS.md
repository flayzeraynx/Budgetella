# Budgetella — Monorepo Genel Bakış

Budgetella, Ozan Kılıç'ın geliştirdiği çok platformlu kişisel finans uygulamasıdır. Bu dizin **birden fazla bağımsız alt projeyi tek repo altında** barındırır. Firebase projesi: `budgetella-d1d41`.

> **Önemli:** Kökteki `README.md`, `CONTRIBUTING.md`, `README-CATEGORY-UPDATE.md`, `README-FIREBASE-EMAIL.md` ve `TRANSLATE-CATEGORIES-README.md` dosyalarının **çoğu eski React/Vite webapp**'i anlatır (artık `OLD/` altında arşivlendi). Aktif kod tabanı native iOS ve native Android uygulamalarıdır.

---

## Alt Projeler (Hangisi Ne)

| Klasör | Durum | Stack | Amaç |
|---|---|---|---|
| `iOS/` | **AKTİF — production** | Swift 6 + SwiftUI + SwiftData + Firebase | Native iOS uygulaması (canlı: v1.1.1 build 3, App Store) |
| `Android/` | **AKTİF — production** | Kotlin + Compose + Hilt + Room + Firebase + Play Billing | iOS ile neredeyse tam parite native Android (canlı: v1.1.4 vc10, Google Play) |
| `web/` | **AKTİF — yayında** | Statik HTML/CSS/JS | Pazarlama sitesi (budgetella.app, EN+TR), Firebase Hosting |
| `budgetella_functions/` | **AKTİF — production backend** | Node.js 20 + Firebase Functions (1st-gen), codebase `default` | Stripe (web), Play Billing RTDN + doğrulama, feedback mail, kategori çeviri job'u |
| `user-cleanup-functions/` | **AKTİF** | Node.js 20, 1st-gen Auth trigger, europe-west3, codebase `user-cleanup` | `clearUserDataOnDelete` — hesap silinince `users/{uid}` + Storage temizliği |
| `functions/` | **DEPRECATED** | Node.js 18 | Eski stub; `firebase.json` buraya bakmıyor. Gerçek kod `budgetella_functions/`'da. |
| `api/` | **LEGACY** | PHP + JSON dosya | Eski webapp'in "Server Sync" backend'i. iOS/Android kullanmıyor. |
| `OLD/` | **ARŞİV — değiştirme** | React 19 + Vite 5 + TypeScript + Dexie + Firebase | Native öncesi orijinal webapp. Salt-okunur referans. |

### Destek klasörleri (proje değil)

- `docs/` — Eski webapp dönemine ait kurulum rehberleri (Firebase, GoDaddy, Google Drive, Server Sync). Native uygulamalar için doğrudan geçerli **değil**.
- `public/` — Eski webapp'in PWA assetleri (manifest, ikonlar).
- `budgetella-icon/` — Üretilmiş app icon paketi (iOS `Contents.json` + Android mipmap + SVG master).
- `budgetella_screens/` — Pazarlama/store screenshotları.
- `claude_design/` — Bağımsız bir TR pazarlama sitesi tasarım denemesi. **Canlı site `web/`**; bu klasör keşif amaçlıdır.

---

## Kökteki Önemli Dosyalar

- `firebase.json` — Hosting → `web/`, Functions → `budgetella_functions/` (codebase `default`) + `user-cleanup-functions/` (codebase `user-cleanup`). Tek doğruluk kaynağı.
- `.firebaserc` — Aktif proje `budgetella-d1d41`.
- `firestore.rules`, `firestore.indexes.json`, `firebase.rules`, `storage.rules` — Firestore/Storage güvenlik & index tanımları.
- `send-test-push.js` & `watch-firestore.js` — Manuel FCM/Firestore debug scriptleri. UID `7n48wY1HdMWD8ZdX00hzqwZAcsb2` hard-coded — kendi UID'inle değiştirmen gerekir.
- `.env` — Kök script'ler için config (şu an sadece functions URL'si; gitignore'da olmasına rağmen git'te tracked).
- PDF'ler — Mobile mockup + UI flow + Tier 3 spec referansları.

---

## Cross-Cutting Gerçekler

- **iOS bundle ID:** `com.ozankilic.budgetella` — Team `ZS9KW29SGF`
- **Android applicationId:** `com.budgetella.app`
- **Firebase project ID:** `budgetella-d1d41`
- **Canlı domain:** `budgetella.app` (Firebase Hosting)
- **V1 piyasası:** Türkiye-only, iPhone-only (iPad ve global rollout sonraki sürümlere)
- **AI:** Gemini 2.5 Flash (iOS: `GeminiInsightService`, `BudgiView`, `CameraEntryContent`; Android: `GeminiChatService`). API anahtarı ve model adı şu an istemcide — sunucu proxy'si planlı.
- **Premium fiyat (iOS StoreKit 2 native, Android Play Billing 9.1, RevenueCat YOK):** $4.99/ay + $39.99/yıl (7 gün free trial) + $99.99 lifetime, ayrı ₺TL tier'ı
- **Eski ad:** Pre-rename kod tabanında "FinVault" geçer (özellikle `OLD/`, `api/data-storage.php`, `CONTRIBUTING.md`).

---

## Ozzy ile Çalışma Notları

- Ana iletişim dili Türkçe. README/dokümantasyon TR + EN karışık. Kod tabanı Türkçe lokalizasyon dahil çift dil destekli.
- Ozzy 4 yıllık kişisel veriyi `~/Downloads/budgetella_backup_2026-05-01.json` üzerinden iOS app'e import etti (Dexie → SwiftData mapping `BackupImportService` içinde).
- iOS ürün tasarımı ve metinlerin doğruluk kaynağı; Android her ekranı aynalar. İki platform da production'da (2026-10).
- Release öncesi: `git branch -r --no-merged main` ile main'e girmemiş düzeltme kalmadığını kontrol et (Gemini 2.5 fix'i 4 ay branch'te kalmıştı).
- Proje tarihçesi, durum, riskler ve yol haritası claude.ai'daki **Budgetella** Project dokümanlarında tutulur.

---

## Yeni Bir Görev İçin Hangi Klasöre Bak?

- "Push notification çalışmıyor" → `iOS/` veya `Android/` + kök `send-test-push.js`
- "Stripe / abonelik" → `budgetella_functions/` (web ödemesi + `play-billing.js`) + `iOS/Budgetella/Core/Services/SubscriptionService.swift` (StoreKit 2) + `Android/BILLING.md`
- "Hesap silme / veri temizliği" → `user-cleanup-functions/`
- "Sitedeki blog yazısı / SEO" → `web/`
- "Kategori çevirileri" → `budgetella_functions/index.js` (`updateAllCategoryTranslations`) + `README-CATEGORY-UPDATE.md`
- "Eski webapp davranışı" → `OLD/` (ama değiştirme — arşiv)

Her alt klasörde kendi `AGENTS.md`'si var; oraya bak.

## Imported Claude Cowork project instructions

This is the financial tracking app's website, IOS and Android native app files
