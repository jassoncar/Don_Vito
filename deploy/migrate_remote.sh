#!/usr/bin/env bash
# Crea las tablas y los datos iniciales (solo administrador) en la base de AWS RDS.
# Uso (con Docker corriendo, desde la raíz del proyecto):  bash deploy/migrate_remote.sh
set -euo pipefail
cd "$(dirname "$0")/.."
source deploy/_load_env.sh

: "${DB_HOST:?}"; : "${DB_PASSWORD:?}"; : "${ADMIN_PASSWORD:?Defina ADMIN_PASSWORD (10+ caracteres)}"
export SEED_PRODUCTION=1
export DB_SSL_MODE="${DB_SSL_MODE:-required}"
export SECRET_KEY_BASE="${SECRET_KEY_BASE:-temporal-solo-para-migrar}"

docker compose run --rm --no-deps --entrypoint sh \
  -e RAILS_ENV=production -e SECRET_KEY_BASE \
  -e DB_HOST -e DB_PORT -e DB_DATABASE -e DB_USERNAME -e DB_PASSWORD -e DB_SSL_MODE \
  -e SEED_PRODUCTION -e ADMIN_EMAIL -e ADMIN_PASSWORD \
  app -c 'bundle check >/dev/null 2>&1 || bundle install; ruby bin/rails db:migrate && ruby bin/rails runner "load Rails.root.join(%q(db/seeds.rb)) if User.count.zero?"'

echo ">> Migraciones y seed de producción terminados."
