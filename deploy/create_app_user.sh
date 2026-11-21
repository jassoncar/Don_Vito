#!/usr/bin/env bash
# Crea la base y el usuario limitado de la aplicación en AWS RDS (se ejecuta una sola vez).
# Uso (desde la raíz del proyecto):  bash deploy/create_app_user.sh
set -euo pipefail
cd "$(dirname "$0")/.."
source deploy/_load_env.sh

: "${DB_HOST:?Defina DB_HOST en deploy/.env.production}"
: "${DB_PASSWORD:?Defina DB_PASSWORD (clave NUEVA para el usuario de la app)}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:-licoreria}"
DB_USERNAME="${DB_USERNAME:-licoreria_app}"

read -r -p "Usuario maestro de RDS [dbadmin]: " MASTER_USER
MASTER_USER="${MASTER_USER:-dbadmin}"
read -r -s -p "Contraseña del usuario maestro: " MASTER_PWD
echo

SQL=$(cat <<SQLEND
CREATE DATABASE IF NOT EXISTS \`${DB_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USERNAME}'@'%' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_DATABASE}\`.* TO '${DB_USERNAME}'@'%';
FLUSH PRIVILEGES;
SQLEND
)

echo ">> Creando base '${DB_DATABASE}' y usuario '${DB_USERNAME}' en ${DB_HOST}..."
if ! printf '%s\n' "$SQL" | docker run --rm -i -e MYSQL_PWD="$MASTER_PWD" mysql:8.4 \
      mysql -h "$DB_HOST" -P "$DB_PORT" -u "$MASTER_USER" --ssl-mode=REQUIRED; then
  echo
  echo "Falló. Revise endpoint, puerto 3306 abierto en el grupo de seguridad y la contraseña maestra."
  echo "Si el error menciona 'mysql_native_password', cree el usuario con el método por defecto:"
  echo "  CREATE USER '${DB_USERNAME}'@'%' IDENTIFIED BY '<clave>';"
  exit 1
fi
echo ">> Listo. Siguiente paso: bash deploy/test_connection.sh"
