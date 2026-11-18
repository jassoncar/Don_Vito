#!/usr/bin/env bash
# Respaldo diario de la base en AWS RDS (la capa gratuita solo conserva 1 día de copias).
# Uso:  bash deploy/backup_remote.sh      (programable con cron; conserva los últimos 14)
set -euo pipefail
cd "$(dirname "$0")/.."
source deploy/_load_env.sh

mkdir -p backups
FILE="backups/respaldo-$(date +%F-%H%M).sql.gz"

docker run --rm -e MYSQL_PWD="$DB_PASSWORD" mysql:8.4 \
  mysqldump -h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USERNAME" --ssl-mode=REQUIRED \
  --single-transaction --no-tablespaces --routines "$DB_DATABASE" | gzip > "$FILE"

ls -1t backups/respaldo-*.sql.gz 2>/dev/null | tail -n +15 | xargs -r rm --
echo ">> Respaldo guardado en $FILE ($(du -h "$FILE" | cut -f1))"
