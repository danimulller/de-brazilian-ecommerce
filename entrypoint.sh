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
#    conforme definido em dbt_project.yml
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
  "target"
)

echo "[dbt] Criando estrutura de pastas do projeto..."

for dir in "${DIRS[@]}"; do
  full_path="${DBT_DIR}/${dir}"
  if [ ! -d "$full_path" ]; then
    mkdir -p "$full_path"
    # Cria um .gitkeep para que o Git rastreie a pasta vazia
    touch "${full_path}/.gitkeep"
    echo "  ✔ Criado: ${dir}"
  else
    echo "  ↷ Já existe: ${dir}"
  fi
done

# ─────────────────────────────────────────────
# 3. Verificar conexão com o banco de dados
# ─────────────────────────────────────────────
echo "[dbt] Verificando conexão com o banco de dados..."

cd "$DBT_DIR"

# Tenta até 10 vezes com intervalo de 3s (o postgres pode demorar)
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
# 4. Manter o container em execução
# ─────────────────────────────────────────────
exec tail -f /dev/null