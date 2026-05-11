#!/bin/bash

set -e

# ─────────────────────────────────────────────
# 1. Create profiles.yml with environment variables
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

echo "[dbt] profiles.yml created at ~/.dbt/profiles.yml"

# ─────────────────────────────────────────────
# 2. Create dbt project folder structure
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

echo "[dbt] Creating project folder structure..."

for dir in "${DIRS[@]}"; do
  full_path="${DBT_DIR}/${dir}"
  if [ ! -d "$full_path" ]; then
    mkdir -p "$full_path"
    touch "${full_path}/.gitkeep"
    echo "  ✔ Created: ${dir}"
  else
    echo "  ↷ Already exists: ${dir}"
  fi
done

# ─────────────────────────────────────────────
# 3. Download Kaggle dataset
# ─────────────────────────────────────────────
DATA_DIR="/data"
DATASET="olistbr/brazilian-ecommerce"
KAGGLE_JSON_PATH="/root/.config/kaggle/kaggle.json"

echo "[kaggle] Checking credentials..."

if [ -z "${KAGGLE_USERNAME}" ] || [ -z "${KAGGLE_KEY}" ]; then
  echo "[kaggle] ❌ KAGGLE_USERNAME and KAGGLE_KEY not defined in .env. Skipping download."
else
  # Configure credentials via JSON file (avoids kaggle CLI warning)
  mkdir -p "$(dirname "${KAGGLE_JSON_PATH}")"
  cat > "${KAGGLE_JSON_PATH}" << EOF
{"username":"${KAGGLE_USERNAME}","key":"${KAGGLE_KEY}"}
EOF
  chmod 600 "${KAGGLE_JSON_PATH}"

  mkdir -p "${DATA_DIR}"

  # Only downloads if the folder is empty (idempotent)
  CSV_COUNT=$(find "${DATA_DIR}" -name "*.csv" 2>/dev/null | wc -l)

  if [ "${CSV_COUNT}" -gt 0 ]; then
    echo "[kaggle] ↷ ${CSV_COUNT} CSV(s) already present in ${DATA_DIR}. Skipping download."
  else
    echo "[kaggle] Downloading dataset '${DATASET}'..."

    kaggle datasets download \
      --dataset "${DATASET}" \
      --path "${DATA_DIR}" \
      --unzip

    echo "[kaggle] ✔ Download completed."
    echo "[kaggle] Files available in ${DATA_DIR}:"
    ls -lh "${DATA_DIR}"/*.csv 2>/dev/null || echo "  (no CSV found after unzip)"
  fi

  # ───────────────────────────────────────────
  # 4. Load CSVs into PostgreSQL `raw` schema
  # ───────────────────────────────────────────
  echo "[loader] Loading CSVs into PostgreSQL (schema: raw)..."

  DATA_DIR="${DATA_DIR}" python /scripts/load_raw_data.py

  echo "[loader] ✔ Database load completed."
fi

# ─────────────────────────────────────────────
# 5. Check dbt connection
# ─────────────────────────────────────────────
echo "[dbt] Checking database connection..."

cd "${DBT_DIR}"

MAX_RETRIES=10
RETRY_INTERVAL=3

for i in $(seq 1 $MAX_RETRIES); do
  if dbt debug --no-version-check 2>&1 | grep -q "Connection test: \[OK\]"; then
    echo "[dbt] ✔ Database connection successfully established."
    break
  fi
  echo "[dbt] Waiting for database... attempt ${i}/${MAX_RETRIES}"
  sleep $RETRY_INTERVAL
done

echo "[dbt] Environment ready. Container running."

# ─────────────────────────────────────────────
# 6. Keep the container running
# ─────────────────────────────────────────────
exec tail -f /dev/null