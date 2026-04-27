#!/bin/bash

# Criar diretório ~/.dbt se não existir
mkdir -p ~/.dbt

# Criar arquivo profiles.yml (sobrescreve sempre para garantir variáveis resolvidas)
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

# Executar o comando original (tail -f /dev/null)
exec tail -f /dev/null