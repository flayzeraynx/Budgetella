# /functions — DEPRECATED

**Bu klasörü kullanma.** Eski Firebase Functions iskelet'i. Aktif production backend `/budgetella_functions` klasöründe.

Kök `firebase.json` `functions.source = "budgetella_functions"` olarak ayarlı — bu klasör deploy'a dahil edilmiyor.

`index.js` neredeyse tamamen comment-out edilmiş ve "kod taşındı" notu içeriyor. Burada hâlâ duran:
- `seed-reviewer.js` — bir kerelik yardımcı script (tarihsel). Çalıştırmaya gerek yoksa dokunma.
- `package.json` — Node 18 runtime tanımı (eskimiş; yeni klasör Node 20).
- `node_modules/` — gitignored olmalı, ama bazen takılmış olabilir.

---

## Eylem

- **Yeni iş yapma**: `/budgetella_functions/CLAUDE.md`'ye git.
- **Temizlik düşünülüyorsa**: bu klasörün tamamı silinebilir, git geçmişinden geri çağrılabilir. Ozzy onaylarsa.
