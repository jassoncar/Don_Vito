#!/usr/bin/env bash
# Prueba la conexión con el usuario de la aplicación.  Uso: bash deploy/test_connection.sh
set -euo pipefail
cd "$(dirname "$0")/.."
source deploy/_load_env.sh

docker run --rm -e MYSQL_PWD="$DB_PASSWORD" mysql:8.4 \
  mysql -h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USERNAME" --ssl-mode=REQUIRED \
  -e "SELECT VERSION() AS version, CURRENT_USER() AS usuario, @@have_ssl AS ssl; SHOW DATABASES;"
