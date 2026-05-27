#!/bin/sh

while true; do
  echo "💾 backup..."

  MYSQL_PWD=$MYSQL_PASSWORD mysqldump \
    -h db \
    -u $MYSQL_USER \
    $MYSQL_DATABASE \
    --single-transaction \
    --quick \
    --lock-tables=false \
    | gzip > /backup/backup_$(date +%F_%H-%M-%S).sql.gz

  find /backup -type f -name "*.sql.gz" -mtime +7 -delete

  echo "done"
  sleep 86400
done