#!/bin/bash
set -e
cd /app

[ -f .env ] || cp .env.example .env

echo ">> Instalando gemas (la primera vez puede tardar unos minutos)..."
bundle check >/dev/null 2>&1 || bundle install

rm -f tmp/pids/server.pid

echo ">> Preparando la base de datos..."
n=0
until ruby bin/rails db:migrate; do
  n=$((n+1))
  if [ "$n" -ge 20 ]; then echo "No se pudo preparar la base de datos."; exit 1; fi
  echo ">> Reintentando en 3 segundos..."
  sleep 3
done

ruby bin/rails runner 'load Rails.root.join("db/seeds.rb") if User.count.zero?'

echo ">> Aplicación lista en http://localhost:${APP_PORT:-8080}"
exec ruby bin/rails server -b 0.0.0.0 -p 3000
