# Budgetella Cloud Functions — Claude Notes

**Production Firebase Cloud Functions backend.** Node.js 20, **1st-gen** Firebase Functions. Kök `firebase.json` `functions.source = "budgetella_functions"` ile bu klasöre işaret eder.

> Eski `/functions` klasörü kullanılmıyor — DEPRECATED. Gerçek backend burası.

---

## Exports (`index.js`)

| Function | Tür | Görev |
|---|---|---|
| `createCheckoutSession` | HTTPS | Stripe Checkout session oluşturur (web premium ödemesi) |
| `handleStripeWebhook` | HTTPS | Stripe webhook'larını işler — abonelik durumu Firestore'a yazılır |
| `cancelSubscription` | HTTPS | Kullanıcı aboneliğini iptal eder |
| `getSubscriptionStatus` | HTTPS | Bir kullanıcının mevcut abonelik durumunu döndürür |
| `sendFeedback` | HTTPS | Feedback formundan gelen mesajı nodemailer ile mail atar |
| `updateAllCategoryTranslations` | HTTPS | Tüm kullanıcıların kategorilerine TR/EN çevirilerini ekler (bir kerelik migration job) |

> iOS uygulaması StoreKit 2 native kullandığı için Stripe akışı **sadece web** içindir. Android Play Billing kendi içinde yürütür.

---

## Kurulum

```bash
cd /Users/flayzeraynx/Development/Budgetella/budgetella_functions
npm install
```

`.env.example`'ı kopyala → `.env` (gitignored). Firebase runtime config zorunlu:

```bash
firebase functions:config:set \
  stripe.secret_key="sk_live_..." \
  stripe.webhook_secret="whsec_..." \
  email.user="..." \
  email.password="..."
```

---

## Çalıştırma & Deploy

```bash
npm run serve                  # Local emulator
npm run deploy                 # Tüm fonksiyonları deploy et
npm run deploy:interactive     # deploy-functions.js — rehberli deploy
```

Yardımcı scriptler:
- `deploy.js` — Tek komut deploy wrapper
- `deploy-functions.js` — Hangi fonksiyonu deploy etmek istediğini soran interaktif CLI
- `deploy-and-run-update.js` — Deploy + `updateAllCategoryTranslations` çağırır (migration için)
- `test.js` — Manuel endpoint testleri

Detaylı deploy adımları: **`DEPLOY.md`**

---

## Stack

| Bağımlılık | Amaç |
|---|---|
| `firebase-functions` | 1st-gen Functions runtime |
| `firebase-admin` | Firestore admin erişimi |
| `stripe` | Checkout + webhook |
| `nodemailer` | Feedback maili |
| `cors` | Web istemcisi için |
| `dotenv` | Local geliştirme env |
| `node-fetch` | HTTP istekler |

---

## Sık Karşılaşılan Görevler

- **Yeni endpoint** → `index.js`'e `exports.<name> = functions.https.onRequest(...)` ekle, deploy.
- **Stripe webhook event'i ekleme** → `handleStripeWebhook` switch'ine yeni case.
- **Feedback maili formatını değiştirme** → `sendFeedback` fonksiyonu içindeki `mailOptions.html` template'i.
- **Kategori çeviri yenileme** → `npm run deploy` sonrası `updateAllCategoryTranslations` endpoint'ini bir kere çağır (veya `deploy-and-run-update.js`).
- **Kategori migration'ı hakkında detay** → kök `README-CATEGORY-UPDATE.md` ve `TRANSLATE-CATEGORIES-README.md`.

---

## Önemli

- Stripe **canlı anahtarlar** functions config'de tutulur, repo'da YOK. Test anahtarı için `.env` kullan.
- `firebase functions:log` ile production loglarını izle.
- 1st-gen runtime → cold start 2-5sn olabilir. Premium kullanıcı sayısı büyürse 2nd-gen migration düşünülebilir.
