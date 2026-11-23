# Budgetella Web — Claude Notes

**Statik pazarlama sitesi.** `budgetella.app` adresinde Firebase Hosting üzerinden yayında. EN + TR çift dilli. **Build adımı yok** — HTML/CSS/JS olduğu gibi serve edilir.

---

## Yapı

```
web/
├── index.html           EN ana sayfa
├── tr.html              TR ana sayfa
├── blog.html            EN blog index
├── blog-tr.html         TR blog index
├── blog/                TR blog yazıları (*.html)
├── privacy.html         /  privacy-tr.html
├── terms.html           /  terms-tr.html
├── support.html         /  support-tr.html
├── favicon.svg
├── apple-touch-icon.png
├── robots.txt
├── sitemap.xml
└── assets/
    ├── style.css        Tüm sayfa stilleri
    ├── site.js          Vanilla JS (nav + footer, scroll davranışları)
    ├── consent.js       Çerez onayı; GA4'ü yalnızca kabul sonrası yükler
    ├── fonts/           Self-hosted Geist / Geist Mono
    ├── vendor/          Self-hosted GSAP 3.12.5
    ├── og-image.png     Open Graph görseli
    └── screenshots/     App store / pazarlama screenshotları
```

---

## Deploy

Kök dizinden Firebase Hosting:

```bash
cd /Users/flayzeraynx/Development/Budgetella
firebase deploy --only hosting
```

`firebase.json` `hosting.public = "web"` + `cleanUrls: true` → `privacy.html` URL'de `/privacy` olarak görünür.

Firebase projesi: `budgetella-d1d41`.

---

## Dil Kuralı

**EN ve TR kardeş sayfalar.** Yeni içerik eklerken her zaman iki dilde:

| EN | TR |
|---|---|
| `index.html` | `tr.html` |
| `blog.html` | `blog-tr.html` |
| `privacy.html` | `privacy-tr.html` |
| `terms.html` | `terms-tr.html` |
| `support.html` | `support-tr.html` |

`blog/` klasörü şu an sadece TR yazılar içerir.

---

## Analytics & çerez onayı

Google Analytics 4 — measurement ID **`G-93JNEYMKHT`**. **Sayfalara `gtag` snippet'i KOYMA.** GA yalnızca `assets/consent.js` üzerinden, ziyaretçi "Kabul et" dedikten sonra yüklenir (seçim `localStorage.budgetella_consent`). Her sayfanın `<head>`'inde `<script src="/assets/consent.js" defer></script>` olmalı. Footer'daki "Çerez tercihleri" (`[data-cookie-prefs]`) banner'ı yeniden açar. Banner stilleri `style.css` sonunda.

Üçüncü taraf istek yok: fontlar `assets/fonts/`, GSAP 3.12.5 `assets/vendor/` altında self-hosted. Yeni CDN/Google Fonts linki ekleme.

---

## SEO Notları

- `sitemap.xml` ve `robots.txt` kökte. Yeni sayfa eklerken sitemap'i güncelle.
- Open Graph + Twitter Card meta tag'leri her sayfanın `<head>`'inde olmalı (`og-image.png` referans).
- `cleanUrls` aktif olduğu için iç linklerde `.html` uzantısı yazma — `/privacy`, `/blog/yazi-slug` formatını kullan.

---

## Sıkça Yapılan Şeyler

- **Yeni blog yazısı (TR)** → `web/blog/<slug>.html` + `web/blog-tr.html` index'e link.
- **Yeni screenshot** → `web/assets/screenshots/` + ilgili sayfada `<img>` referansı.
- **Pricing değişikliği** → `index.html` + `tr.html` ikisinde de güncelle. iOS app'in fiyatıyla tutarlı kalmalı ($4.99/ay + $39.99/yıl).
- **Privacy/Terms güncellemesi** → her iki dilde + tarih damgası.

---

## Yakın İlişkili Dosyalar

- Eski webapp linki → artık verilmiyor; native iOS App Store + Play Store linkleri öne çıkarılır.
