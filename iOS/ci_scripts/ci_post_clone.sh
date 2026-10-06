#!/bin/sh

# ci_post_clone.sh — Xcode Cloud
# Klonlamadan sonra, bağımlılıklar resolve edilmeden ÖNCE çalışır.
# Görevi: gitignored dosyaları (xcodeproj, secrets) bulut ortamında üretmek.
#
# Gerekli ortam değişkenleri (App Store Connect → Xcode Cloud → Workflow → Environment):
#   GEMINI_API_KEY                       (Secret)  — Google AI Studio key
#   GOOGLE_SERVICE_INFO_PLIST_BASE64     (Secret)  — GoogleService-Info.plist'in base64'ü
#
# Hata olursa build'i ANINDA durdur (sessiz boş key ile devam etme).
set -e

echo "▸ ci_post_clone başladı"

# Xcode Cloud repo kökünü buraya verir; iOS app alt klasörde.
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
IOS_DIR="$REPO_ROOT/iOS"
echo "▸ REPO_ROOT=$REPO_ROOT"

# 1) XcodeGen kur ve projeyi üret -------------------------------------------
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "▸ xcodegen kuruluyor (brew)…"
  brew install xcodegen
fi

echo "▸ xcodegen generate"
cd "$IOS_DIR"
xcodegen generate

# 2) Secrets.xcconfig'i env var'dan yaz -------------------------------------
if [ -z "$GEMINI_API_KEY" ]; then
  echo "✗ GEMINI_API_KEY env var boş — workflow Environment'a ekle." >&2
  exit 1
fi
CONFIG_DIR="$IOS_DIR/Budgetella/Configuration"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/Secrets.xcconfig" <<EOF
// Xcode Cloud tarafından ci_post_clone.sh ile üretildi — commit etme
GEMINI_API_KEY = $GEMINI_API_KEY
EOF
echo "▸ Secrets.xcconfig yazıldı (key length: ${#GEMINI_API_KEY})"

# 3) GoogleService-Info.plist'i base64 env var'dan çöz ----------------------
if [ -z "$GOOGLE_SERVICE_INFO_PLIST_BASE64" ]; then
  echo "✗ GOOGLE_SERVICE_INFO_PLIST_BASE64 env var boş — workflow Environment'a ekle." >&2
  exit 1
fi
RES_DIR="$IOS_DIR/Budgetella/Resources"
mkdir -p "$RES_DIR"
echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode > "$RES_DIR/GoogleService-Info.plist"

# plist geçerli mi doğrula (bozuk base64'te erken patla)
plutil -lint "$RES_DIR/GoogleService-Info.plist" >/dev/null
echo "▸ GoogleService-Info.plist yazıldı + doğrulandı"

echo "✓ ci_post_clone tamam"
