# Budgetella iOS — Release Log

---

## v1.0.0 (build 15) — 2026-05-06
**App Store review'a gönderildi.**

### Eklenenler
- **Auth:** Welcome, Sign In, Sign Up, Forgot Password, OTP doğrulama, Face ID/Touch ID setup + lock ekranları
- **Dashboard:** Gelir/gider özeti, dönemsel kart bileşenleri, DashboardViewModel
- **Transactions:** Liste görünümü, düzenleme sheet'i, filtre/arama
- **Quick Entry:** Manuel giriş, ses girişi (Voice), kamera ile fiş OCR
- **Settings:** Profil yönetimi, kategori yönetimi, abonelik yönetimi, bildirim ayarları, destek, hesap silme
- **Stats:** StatsView + BudgiView (Gemini 2.0 Flash destekli AI insights)
- **Onboarding:** 4 adımlı akış, backup dosyası import adımı dahil
- **Paywall:** StoreKit 2 native — aylık $4.99, yıllık $39.99, lifetime $99.99; 7 gün free trial
- **Push Notifications:** FCM entegrasyonu, NotificationsInboxView
- **Widget Extension:** Ana ekran widget (WidgetKit)
- **Siri Shortcuts:** AddTransactionIntent (App Intents)
- **Firebase Analytics:** Temel event tracking
- **Backup:** BackupExportService + BackupImportService (4 yıllık webapp verisi import)

### Altyapı
- Swift 6 strict concurrency, iOS 17+ deployment target
- SwiftData @Model: Transaction, Category, Budget, Goal, Achievement, User, AppSettings, SubscriptionRecord, NotificationRecord
- FirebaseAuth + Sign in with Apple + GoogleSignIn + LocalAuthentication
- Firestore sync (premium tier), Keychain token persist
- KeywordCategorizer — TR keyword fallback (Migros, Vodafone, Shell, A101, BP, Akbank vb.)
- GeminiInsightService — Gemini 2.0 Flash, günlük UserDefaults cache
- Design System: Colors (#6E5BFF accent), Typography (Inter), Spacing (4/8/12/16/24/32), BrandAlert, ShimmerModifier
- XcodeGen project.yml — reproducible build (Xcodeproj git'lenmiyor)
- Localizable.xcstrings (TR/EN)

### Milestone'lar
| Tarih | Olay |
|---|---|
| 2026-05-01 | iOS native development başladı; proje iskeleti, modeller, RevenueCat → StoreKit 2 geçişi |
| 2026-05-02 | Auth flow, design system, core services |
| 2026-05-03 | Feature ekranları (Dashboard, Transactions, Settings, QuickEntry) |
| 2026-05-04 | IAP entegrasyonu (StoreKit 2), Firebase Analytics |
| 2026-05-05 | TestFlight 1.0.0 yayını; translation fix, bug fixes, push notifications |
| 2026-05-06 | Final build (build 15); App Store review'a gönderildi |

### Notlar
- RevenueCat planlanmıştı; 2026-05-01'de native StoreKit 2 ile değiştirildi (bağımlılık azaltma)
- Gemini 2.0 Flash insight servisi için kullanılıyor; Claude OCR entegrasyonu V1.1'e ertelendi
- Bundle ID: `com.ozankilic.budgetella` (eski README'deki `com.toprakkilic` hatalıydı, düzeltildi)
- Insights feature klasörü açık fakat içerik yok; V1.1'e alındı

---

## v0.x — React Webapp (Deprecated)
*2025-03-29 → 2026-04-30 arasındaki webapp geliştirme süreci.*
*Native iOS relaunch kararıyla rafa kalktı (2026-05-01). Webapp `budgetella.app` marketing landing'e dönüştürülecek.*

| Tarih | Olay |
|---|---|
| 2025-03-29 | Initial commit — React webapp |
| 2025-03-30 | Domain live, email sign in, kategori fix |
| 2025-03-31 | Stripe entegrasyonu, abonelik yönetimi, dil desteği |
| 2025-04-01 | Premium özellikler, Google login, aylık abonelik çalışır hale getirildi |
| 2025-04-02 | Firebase Functions deploy, responsive transaction list |
| 2025-04-03 | Kullanıcı profili, canlı yayın güncellemeleri |
| 2025-12-09 | npm fix |
| 2025-12-23 | Genel commit |
| 2026-02-18 | Comply updates |
| 2026-02-24 | Güvenlik: secrets gitignore'a eklendi, debug log'lar temizlendi |
| 2026-05-01 | **Deprecated** — native iOS'a geçiş kararı |
