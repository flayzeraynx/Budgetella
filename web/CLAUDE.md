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
    ├── site.js          Vanilla JS (nav, analytics tetikleyici, vs)
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

## Analytics

Google Analytics 4 — measurement ID **`G-93JNEYMKHT`**. Tüm sayfalara aynı `gtag` snippet'i koyulur (`<head>` içinde).

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

- Form submit'leri (varsa) → `budgetella_functions/index.js` içindeki `sendFeedback` HTTPS endpoint'ine POST eder.
- Eski webapp linki → artık verilmiyor; native iOS App Store + Play Store linkleri öne çıkarılır.
