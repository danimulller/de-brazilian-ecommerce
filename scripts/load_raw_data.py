"""
load_raw_data.py
────────────────
Carrega todos os CSVs do dataset Olist (/data) no schema `raw` do PostgreSQL.
Cada arquivo vira uma tabela: olist_customers_dataset.csv → raw.olist_customers_dataset
"""

import os
import sys
import time
import logging
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

# ── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Configuração via variáveis de ambiente ────────────────────────────────────
DB_HOST     = os.environ["DB_HOST"]
DB_PORT     = os.environ.get("DB_PORT", "5432")
DB_NAME     = os.environ["DB_NAME"]
DB_USER     = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
DATA_DIR    = Path(os.environ.get("DATA_DIR", "/data"))
RAW_SCHEMA  = "raw"

# CSVs que não devem ser carregados no banco (sem extensão)
EXCLUDED_TABLES = {
    "olist_geolocation_dataset",
}

DATABASE_URL = (
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# ── Mapeamento de tipos especiais por coluna ──────────────────────────────────
# Colunas que chegam como string mas representam datas
DATE_COLS = {
    "olist_orders_dataset": [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "olist_order_reviews_dataset": [
        "review_creation_date",
        "review_answer_timestamp",
    ],
}


def wait_for_db(engine, retries: int = 15, interval: int = 3) -> None:
    """Aguarda o PostgreSQL estar pronto."""
    for attempt in range(1, retries + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            log.info("Conexão com o banco estabelecida.")
            return
        except Exception as exc:
            log.warning("Banco indisponível (tentativa %d/%d): %s", attempt, retries, exc)
            time.sleep(interval)
    log.error("Não foi possível conectar ao banco após %d tentativas.", retries)
    sys.exit(1)


def create_schema(engine) -> None:
    with engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {RAW_SCHEMA}"))
    log.info("Schema '%s' garantido.", RAW_SCHEMA)


def load_csv(engine, csv_path: Path) -> None:
    table_name = csv_path.stem  # remove extensão .csv

    log.info("Carregando %-55s → %s.%s", csv_path.name, RAW_SCHEMA, table_name)

    df = pd.read_csv(csv_path, low_memory=False)

    # Converte colunas de data quando conhecidas
    for col in DATE_COLS.get(table_name, []):
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce")

    df.to_sql(
        name=table_name,
        con=engine,
        schema=RAW_SCHEMA,
        if_exists="replace",   # recria sempre → idempotente
        index=False,
        chunksize=5_000,
        method="multi",
    )

    log.info("  ✔ %d linhas carregadas em %s.%s", len(df), RAW_SCHEMA, table_name)


def main() -> None:
    csv_files = sorted(DATA_DIR.glob("*.csv"))

    if not csv_files:
        log.error(
            "Nenhum CSV encontrado em '%s'. "
            "Verifique se o download do Kaggle foi concluído.",
            DATA_DIR,
        )
        sys.exit(1)

    log.info("Encontrados %d arquivo(s) CSV em '%s'.", len(csv_files), DATA_DIR)

    engine = create_engine(DATABASE_URL, pool_pre_ping=True)

    wait_for_db(engine)
    create_schema(engine)

    errors = []
    for csv_path in csv_files:
        if csv_path.stem in EXCLUDED_TABLES:
            log.info("  ⏭ Ignorado (excluído): %s", csv_path.name)
            continue
        try:
            load_csv(engine, csv_path)
        except Exception as exc:
            log.error("Erro ao carregar '%s': %s", csv_path.name, exc)
            errors.append(csv_path.name)

    if errors:
        log.error("Falha ao carregar: %s", ", ".join(errors))
        sys.exit(1)

    log.info("✅ Todos os CSVs foram carregados no schema '%s' com sucesso.", RAW_SCHEMA)


if __name__ == "__main__":
    main()