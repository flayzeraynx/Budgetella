# Budgetella App Icon · Wordmark B

## iOS
ios/ klasörü → Xcode'da Assets.xcassets → AppIcon olarak ekle.
NOT: Apple convention'unda dosya isimleri normalde @2x / @3x içerir; bu pakette
@ → -2x / -3x olarak yazıldı (filesystem uyumu için). Contents.json mevcut isimlerle çalışır;
istersen Xcode'a koymadan önce -2x → @2x rename yapabilirsin.

## Android
android/mipmap-* klasörlerini app/src/main/res/ altına kopyala.
- Legacy: ic_launcher.png
- Adaptive (API 26+): ic_launcher_foreground.png + ic_launcher_background.png
- Manifest XML: mipmap-anydpi-v26/ic_launcher.xml

## Play Store
android/play-store-512.png — store listing yüksek çözünürlük

## Master
svg/icon-master-1024.svg — yeniden boyutlandırma için vector kaynak

## Renkler
- Bg gradient: #6E5BFF → #8B6FFF → #5B47E0
- Wordmark: #FFFFFF (B harfi)
- Tasarruf nokta: #10F2A5

— Budgetella · 4 May 2026
