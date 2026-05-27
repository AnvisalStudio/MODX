=#!/bin/sh
set -eu

echo "🚀 MODX FILES BOOT START"

apk add --no-cache \
  wget \
  unzip

# =========================
# ENV CHECK (MINIMUM ONLY)
# =========================

: "${MODX_VERSION:?MODX_VERSION not set}"

# =========================
# SKIP IF ALREADY INSTALLED
# =========================

if [ -f /var/www/html/core/config/config.inc.php ]; then
  echo "✅ MODX already installed, skipping"
  exit 0
fi

# =========================
# CLEAN WORKDIR
# =========================

rm -rf /tmp/modx_src /tmp/modx.zip
mkdir -p /tmp/modx_src

cd /tmp

# =========================
# DOWNLOAD MODX
# =========================

URL="https://github.com/AnvisalStudio/MODX/releases/download/modx-${MODX_VERSION}-pl/modx-${MODX_VERSION}-pl.zip"

echo "📦 Download MODX: ${MODX_VERSION}"
echo "🔗 $URL"

wget -O modx.zip "$URL"

if [ ! -s modx.zip ]; then
  echo "❌ MODX download failed"
  exit 1
fi

echo "✅ ZIP downloaded"

# =========================
# EXTRACT
# =========================

unzip -q modx.zip -d /tmp/modx_src

SRC_DIR=$(find /tmp/modx_src -maxdepth 2 -type d -name core | head -n 1 | xargs dirname || true)

if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR/core" ]; then
  echo "❌ MODX source not found"
  find /tmp/modx_src -maxdepth 3 -type d
  exit 1
fi

echo "📂 Source found: $SRC_DIR"

# =========================
# COPY FILES
# =========================

rm -rf /var/www/html/*
cp -r "$SRC_DIR"/. /var/www/html/

# =========================
# PERMISSIONS (MODX SAFE)
# =========================

echo "🔧 setting MODX permissions..."

# базовые директории MODX
mkdir -p /var/www/html/core/cache
mkdir -p /var/www/html/core/packages
mkdir -p /var/www/html/core/config
mkdir -p /var/www/html/assets

# критически важные права записи для installer
chmod -R 777 /var/www/html/core
chmod -R 777 /var/www/html/assets

# на всякий случай (иногда MODX пишет сюда временные файлы)
chmod -R 777 /var/www/html

echo "✅ MODX ready for manual installation"

# =========================
# CLEANUP
# =========================

rm -rf /tmp/modx_src /tmp/modx.zip

echo "🎉 MODX FILES SETUP COMPLETE"