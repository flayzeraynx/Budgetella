# /docs — Setup Rehberleri (Eski Webapp Dönemi)

Bu klasördeki tüm Markdown dosyaları **eski React/Vite webapp dönemine ait kurulum rehberleridir**. Native iOS + Android için doğrudan geçerli değildir; ama bazı parçalar (Firebase project setup, Firestore rules) hâlâ referans olabilir.

| Dosya | Konu | Native için geçerlilik |
|---|---|---|
| `firebase-deployment.md` | Eski webapp'i Firebase Hosting'e deploy | KISMİ — Hosting bölümü `web/` için de geçerli |
| `firebase-setup-guide.md` | `budgetella-d1d41` projesi setup | KISMİ — proje yapısı doğru, ama eski webapp client config'i içerir |
| `godaddy-deployment.md` | `/api` PHP'sini GoDaddy'ye yükleme | Sadece `/api` için |
| `google-drive-setup.md` | Eski webapp'in Drive backup feature'ı | YOK — native'de bu feature taşınmadı |
| `server-sync-setup.md` | `/api` JSON server sync modu | Sadece `/api` için |
| `user-guide.md` | End-user için webapp kullanım rehberi | Eski; native app'in kendi UX'i var |

---

## Ne Zaman Buraya Bakılır

- Firebase projesinin (`budgetella-d1d41`) hangi servisleri açıldı diye bakarken → `firebase-setup-guide.md`
- `/api` veya `OLD/` ile uğraşıyorken → ilgili dosya
- Yeni iOS/Android dokümantasyonu için → BURAYA YAZMA, ilgili klasörün `CLAUDE.md` veya `README.md`'sine ekle.

---

## Aksiyon

Bu klasördeki dosyalar **güncellenmiyor**. Yeni rehber eklemek istersen:
- iOS için → `iOS/README.md` veya yeni bir `iOS/docs/`
- Android için → `Android/README.md` (henüz yok, oluşturulmalı)
- Web için → `web/` içinde inline yorumlar veya yeni MD
- Functions için → `budgetella_functions/DEPLOY.md`
