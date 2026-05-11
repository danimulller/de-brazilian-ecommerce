FROM python:3.11-slim

LABEL maintainer="PROJECT"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    vim \
    nano \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /dbt
VOLUME /dbt

WORKDIR /dbt

# dbt
RUN pip install --no-cache-dir \
    dbt-core==1.11.8 \
    dbt-postgres==1.10.0

# Download do Kaggle + carga no PostgreSQL
RUN pip install --no-cache-dir \
    kaggle \
    pandas \
    psycopg2-binary \
    sqlalchemy

EXPOSE 8080 3333

CMD ["/bin/bash"]