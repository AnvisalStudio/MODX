#!/bin/sh
set -eu

echo "🚀 MODX PRODUCTION BOOT START"

apk add --no-cache \
  wget \
  unzip \
  bash \
  mariadb-client \
  netcat-openbsd

# =========================
# ENV CHECK (CRITICAL)
# =========================
: "${MYSQL_USER:?MYSQL_USER not set}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD not set}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE not set}"
: "${MODX_VERSION:?MODX_VERSION not set}"
: "${MODX_TABLE_PREFIX:?MODX_TABLE_PREFIX not set}"
: "${MODX_ADMIN_USER:?MODX_ADMIN_USER not set}"
: "${MODX_ADMIN_PASSWORD:?MODX_ADMIN_PASSWORD not set}"
: "${MODX_ADMIN_EMAIL:?MODX_ADMIN_EMAIL not set}"

# =========================
# WAIT DB (HARD RELIABLE)
# =========================
echo "⏳ Waiting DB..."

i=0
until nc -z db 3306 && \
  MYSQL_PWD="${MYSQL_PASSWORD}" mysql -h db -u"${MYSQL_USER}" "${MYSQL_DATABASE}" -e "SELECT 1" >/dev/null 2>&1; do

  i=$((i+1))
  echo "⏳ Waiting DB... ($i)"
  sleep 2

  if [ "$i" -gt 60 ]; then
    echo "❌ DB TIMEOUT"
    exit 1
  fi
done

echo "✅ DB READY"

# =========================
# SKIP IF ALREADY INSTALLED
# =========================
if [ -f /var/www/html/core/config/config.inc.php ]; then
  echo "✅ MODX already installed"
  exit 0
fi

# =========================
# CLEAN WORKDIR
# =========================
rm -rf /tmp/modx_src /tmp/modx.zip
mkdir -p /tmp/modx_src

cd /tmp

# =========================
# 3. DOWNLOAD MODX (FIXED SOURCE)
# =========================
cd /tmp

URL="https://github.com/AnvisalStudio/MODX/archive/refs/tags/modx-${MODX_VERSION}-pl.zip"

echo "📦 Download MODX: ${MODX_VERSION}"
echo "🔗 $URL"

wget -q --show-progress -O modx.zip "$URL"

# check download
if [ ! -s modx.zip ]; then
  echo "❌ EMPTY ZIP (download failed)"
  exit 1
fi

# verify zip signature
head -c 4 modx.zip | grep -q "PK" || {
  echo "❌ INVALID ZIP (not a real archive)"
  exit 1
}

# =========================
# EXTRACT
# =========================
unzip -q modx.zip -d /tmp/modx_src

# GitHub archive structure fix:
# /tmp/modx_src/modx-2.8.8-pl/...
SRC_DIR=$(find /tmp/modx_src -maxdepth 2 -type d -name "core" | head -n 1 | xargs dirname || true)

if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR/core" ]; then
  echo "❌ MODX SOURCE NOT FOUND"
  echo "DEBUG CONTENT:"
  find /tmp/modx_src -maxdepth 3 -type d
  exit 1
fi

echo "📂 SOURCE OK: $SRC_DIR"

# =========================
# COPY INTO WEB ROOT
# =========================
rm -rf /var/www/html/*
cp -r "$SRC_DIR"/. /var/www/html/

# =========================
# FIX PERMISSIONS (CRITICAL FOR MODX)
# =========================
mkdir -p /var/www/html/core/cache
chmod -R 777 /var/www/html/core/cache
chmod -R 777 /var/www/html/core/packages || true
chmod -R 777 /var/www/html/assets

# =========================
# RUN INSTALLER
# =========================
cd /var/www/html

echo "⚙ Running MODX installer..."

php setup/index.php --installmode=new \
  --database_server=db \
  --database_user="${MYSQL_USER}" \
  --database_password="${MYSQL_PASSWORD}" \
  --database="${MYSQL_DATABASE}" \
  --table_prefix="${MODX_TABLE_PREFIX}" \
  --admin_user="${MODX_ADMIN_USER}" \
  --admin_password="${MODX_ADMIN_PASSWORD}" \
  --admin_email="${MODX_ADMIN_EMAIL}" \
  --language=en

# =========================
# FINAL CLEANUP
# =========================
rm -rf /tmp/modx.zip /tmp/modx_src
touch /var/www/html/.modx-installed

echo "🎉 MODX PRODUCTION BOOT COMPLETE"