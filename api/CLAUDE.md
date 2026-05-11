# /api — Legacy PHP Server-Sync API

**Eski webapp'in (`OLD/`) opsiyonel "Server Sync" backend'i.** Plain PHP, framework yok, composer yok. JSON-on-disk depolama.

> **iOS ve Android uygulamaları bunu KULLANMIYOR.** Sadece arşiv webapp için. Yeni native uygulamalar Firebase'e doğrudan bağlanır + Stripe akışı için `budgetella_functions/`'a gider.

---

## Endpoint'ler

| Dosya | Görev |
|---|---|
| `data-storage.php` | `GET` mevcut JSON state'i döner, `POST` üzerine yazar. Tek bir dosya: `./data/finvault_data.json` (eski "FinVault" adı). |
| `send-feedback.php` | Feedback formundan POST alır → PHP `mail()` ile gönderir. |
| `mail-test.php` | SMTP/`mail()` çalışıyor mu diye diagnostic. |
| `test.php`, `test.html` | Hosting'in PHP çalıştırıp çalıştırmadığını kontrol için. |
| `.htaccess` | CORS header'ları, vs. |

---

## Deploy

Klasörü PHP destekli paylaşımlı hosting'e (örn. GoDaddy) FTP/cPanel ile yükle. Detaylar: kök `docs/godaddy-deployment.md` ve `docs/server-sync-setup.md`.

Veri yolu kontrolü:
- `./data/` klasörü web sunucusu tarafından **yazılabilir** olmalı (chmod 755 veya 775).
- `finvault_data.json` HTTP üzerinden direkt okunmamalı — `.htaccess` ile koruma var ama production'da `/data/` klasörü için indeksi kapat.

---

## Önemli Notlar

- "FinVault" referansı Budgetella'nın eski adıdır — repository tarihçesi.
- Yeni özelliklerle GELİŞTİRİLMİYOR. Var olduğu için duruyor (henüz Server Sync modu kullanan kullanıcılar için).
- Şifre/auth yok — tek dosya state. Birden fazla kullanıcı için tasarlanmamış.
- `send-feedback.php`'nin yerini bugünkü pipeline'da `budgetella_functions/index.js`'in `sendFeedback` fonksiyonu aldı.

---

## Eğer Buraya Geliyorsan

Muhtemelen eski webapp davranışını debug ediyorsun. Hareket etmeden önce `OLD/CLAUDE.md`'ye bak — büyük ihtimalle değişiklik yapmaman gerekiyor.
