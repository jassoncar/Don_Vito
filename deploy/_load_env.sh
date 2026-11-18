# Carga deploy/.env.production (tolera saltos de línea de Windows). Se usa con: source deploy/_load_env.sh
ENV_FILE="deploy/.env.production"
if [ ! -f "$ENV_FILE" ]; then
  echo "Falta $ENV_FILE. Copie deploy/env.production.example a $ENV_FILE y complételo."
  exit 1
fi
set -a
# shellcheck disable=SC1090
source <(tr -d '\r' < "$ENV_FILE")
set +a
