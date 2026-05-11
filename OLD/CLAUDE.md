# /OLD — Archived React/Vite Webapp

**Bu klasör arşivdir. Değiştirme.** Native iOS + Android pivot'undan önceki orijinal Budgetella webapp'i. Salt-okunur referans olarak duruyor — production'da kullanılmıyor.

> Kökteki `README.md`, `CONTRIBUTING.md`, `README-CATEGORY-UPDATE.md`, `README-FIREBASE-EMAIL.md` ve `TRANSLATE-CATEGORIES-README.md` dosyalarının **çoğu bu webapp'i anlatır**, native uygulamaları DEĞİL. Çatallama riski var, dikkatli ol.

---

## Stack (Referans)

| Katman | Teknoloji |
|---|---|
| Build | Vite 5 |
| Framework | React 19 + TypeScript |
| Stil | Tailwind CSS 3 + Headless UI + Lucide icons |
| Local persistence | Dexie 4 (IndexedDB wrapper) |
| Backend | Firebase 11 (Auth, Firestore) + opsiyonel `/api` PHP sync |
| Auth | Firebase Auth + `@react-oauth/google` + `gapi-script` (Google Drive backup) |
| Grafik | Chart.js + react-chartjs-2 |
| Routing | react-router-dom 7 |
| i18n | i18next |
| Tarih | date-fns |

---

## Yapı

```
OLD/
├── src/
│   ├── App.tsx
│   ├── components/         UI bileşenleri
│   ├── context/            React context provider'lar
│   ├── db/                 Dexie schema + helpers
│   ├── firebase/           Firebase config + sync logic
│   ├── i18n/               i18next setup + TR/EN translations
│   └── pages/              Route bazlı sayfalar
├── dist/                   Build artifact (commit edilmiş)
├── translate-categories*.js   Kategori çeviri scripti (eski iş akışı)
├── check-translations.js
├── deploy-app.js           Eski deploy scripti
├── package.json            Tüm webapp bağımlılıkları
├── eslint.config.js
└── vite.config.* + tsconfig.*
```

---

## Önemli

- **iOS app'in `BackupImportService`'i bu webapp'in Dexie schema'sını anlar.** Ozzy'nin 4 yıllık verisi bu webapp'ten export edildi (`budgetella_backup_2026-05-01.json`) ve iOS app'e import edildi.
- Eğer Dexie schema'sının nasıl göründüğünü merak ediyorsan: `OLD/src/db/` altına bak. iOS `Core/Models/` ile karşılaştır.
- Kategori çeviri job'u native dönemde **`budgetella_functions/index.js`'in `updateAllCategoryTranslations`'ına taşındı**. `OLD/translate-categories*.js` scriptleri eski versiyon.

---

## Çalıştırmaman Gereken Şeyler

- `npm run deploy` — eski Firebase Hosting hedefine işaret edebilir, canlı siteyi (`web/`) ezme riski. Önce `package.json` script'lerini incele.
- `translate-categories*.js` — production Firestore'a yazıyor. `budgetella_functions/` üzerinden git.
- `dist/` regenerate etme — gereksiz.

---

## Sorun Giderme

- Kullanıcı "Server Sync"'ten bahsediyorsa → `/api` (PHP) + `OLD/src/firebase/` (eski sync layer)
- Kullanıcı "Google Drive backup"tan bahsediyorsa → `docs/google-drive-setup.md` + `OLD/src/` içinde `gapi-script` kullanımı
- Kullanıcı eski webapp'i lokal koşturmak isterse: `cd OLD && npm install && npm run dev` — ama API key'ler eskimiş olabilir.
