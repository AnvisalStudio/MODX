#!/bin/sh

set -eu

mkdir -p /backup

echo "💾 backup loop started"

# =========================
# WAIT FOR MYSQL (CRITICAL FIX)
# =========================
echo "⏳ waiting for MySQL..."

i=0
until MYSQL_PWD="$MYSQL_PASSWORD" mysqladmin \
  -h db \
  -u "$MYSQL_USER" ping --silent; do

  i=$((i+1))
  echo "⏳ waiting MySQL... ($i)"
  sleep 2

  if [ "$i" -gt 60 ]; then
    echo "❌ MySQL timeout"
    exit 1
  fi
done

echo "✅ MySQL ready"

# =========================
# BACKUP LOOP
# =========================
while true; do

  FILE="/backup/backup_$(date +%F_%H-%M-%S).sql.gz"

  echo "💾 Running DB backup..."

  MYSQL_PWD="$MYSQL_PASSWORD" mysqldump \
    -h db \
    -u "$MYSQL_USER" \
    "$MYSQL_DATABASE" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --skip-lock-tables \
    --no-tablespaces \
  | gzip > "$FILE"

  echo "✔ saved: $FILE"

  find /backup -type f -name "*.sql.gz" -mtime +30 -delete

  echo "🧹 cleanup done"

  sleep 86400
done