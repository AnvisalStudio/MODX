#!/bin/sh

FILE="/backup/backup_$(date +%F_%H-%M-%S).sql.gz"

MYSQL_PWD="$MYSQL_PASSWORD" mysqldump \
  -h db \
  -u "$MYSQL_USER" \
  "$MYSQL_DATABASE" \
  --single-transaction \
  --quick \
  --lock-tables=false \
  --column-statistics=0 \
| gzip > "$FILE"

echo "backup saved: $FILE"

find /backup -type f -name "*.sql.gz" -mtime +7 -delete