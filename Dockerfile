FROM python:3.11-slim

LABEL maintainer="PROJECT"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    vim \
    nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /dbt
VOLUME /dbt

WORKDIR /dbt

RUN pip install dbt-core==1.11.8
RUN pip install dbt-postgres==1.10.0

EXPOSE 8080 3333

CMD ["/bin/bash"]
