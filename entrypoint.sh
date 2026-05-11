#!/bin/bash

set -e

# ─────────────────────────────────────────────
# 1. Criar profiles.yml com variáveis de ambiente
# ─────────────────────────────────────────────
mkdir -p ~/.dbt

cat > ~/.dbt/profiles.yml << EOF
ecommerce:
  target: dev
  outputs:
    dev:
      type: postgres
      host: ${DB_HOST}
      port: ${DB_PORT}
      user: ${DB_USER}
      password: ${DB_PASSWORD}
      dbname: ${DB_NAME}
      schema: public
      threads: 1
EOF

echo "[dbt] profiles.yml criado em ~/.dbt/profiles.yml"

# ─────────────────────────────────────────────
# 2. Criar estrutura de pastas do projeto dbt
# ─────────────────────────────────────────────
DBT_DIR="/dbt"

DIRS=(
  "models/stage"
  "models/intermediate"
  "models/marts"
  "analyses"
  "tests"
  "seeds"
  "macros"
  "snapshots"
)

echo "[dbt] Criando estrutura de pastas do projeto..."

for dir in "${DIRS[@]}"; do
  full_path="${DBT_DIR}/${dir}"
  if [ ! -d "$full_path" ]; then
    mkdir -p "$full_path"
    touch "${full_path}/.gitkeep"
    echo "  ✔ Criado: ${dir}"
  else
    echo "  ↷ Já existe: ${dir}"
  fi
done

# ─────────────────────────────────────────────
# 3. Download do dataset Kaggle
# ─────────────────────────────────────────────
DATA_DIR="/data"
DATASET="olistbr/brazilian-ecommerce"
KAGGLE_JSON_PATH="/root/.config/kaggle/kaggle.json"

echo "[kaggle] Verificando credenciais..."

if [ -z "${KAGGLE_USERNAME}" ] || [ -z "${KAGGLE_KEY}" ]; then
  echo "[kaggle] ❌ KAGGLE_USERNAME e KAGGLE_KEY não definidos no .env. Pulando download."
else
  # Configura credenciais via arquivo JSON (evita warning do kaggle CLI)
  mkdir -p "$(dirname "${KAGGLE_JSON_PATH}")"
  cat > "${KAGGLE_JSON_PATH}" << EOF
{"username":"${KAGGLE_USERNAME}","key":"${KAGGLE_KEY}"}
EOF
  chmod 600 "${KAGGLE_JSON_PATH}"

  mkdir -p "${DATA_DIR}"

  # Só faz download se a pasta estiver vazia (idempotente)
  CSV_COUNT=$(find "${DATA_DIR}" -name "*.csv" 2>/dev/null | wc -l)

  if [ "${CSV_COUNT}" -gt 0 ]; then
    echo "[kaggle] ↷ ${CSV_COUNT} CSV(s) já presentes em ${DATA_DIR}. Pulando download."
  else
    echo "[kaggle] Baixando dataset '${DATASET}'..."

    kaggle datasets download \
      --dataset "${DATASET}" \
      --path "${DATA_DIR}" \
      --unzip

    echo "[kaggle] ✔ Download concluído."
    echo "[kaggle] Arquivos disponíveis em ${DATA_DIR}:"
    ls -lh "${DATA_DIR}"/*.csv 2>/dev/null || echo "  (nenhum CSV encontrado após unzip)"
  fi

  # ───────────────────────────────────────────
  # 4. Carregar CSVs no schema `raw` do PostgreSQL
  # ───────────────────────────────────────────
  echo "[loader] Carregando CSVs no PostgreSQL (schema: raw)..."

  DATA_DIR="${DATA_DIR}" python /scripts/load_raw_data.py

  echo "[loader] ✔ Carga no banco concluída."
fi

# ─────────────────────────────────────────────
# 5. Verificar conexão dbt
# ─────────────────────────────────────────────
echo "[dbt] Verificando conexão com o banco de dados..."

cd "${DBT_DIR}"

MAX_RETRIES=10
RETRY_INTERVAL=3

for i in $(seq 1 $MAX_RETRIES); do
  if dbt debug --no-version-check 2>&1 | grep -q "Connection test: \[OK\]"; then
    echo "[dbt] ✔ Conexão com o banco estabelecida com sucesso."
    break
  fi
  echo "[dbt] Aguardando banco de dados... tentativa ${i}/${MAX_RETRIES}"
  sleep $RETRY_INTERVAL
done

echo "[dbt] Ambiente pronto. Container em execução."

# ─────────────────────────────────────────────
# 6. Manter o container em execução
# ─────────────────────────────────────────────
exec tail -f /dev/null