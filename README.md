- docker compose down
- docker compose build --no-cache
- docker compose up -d
- docker compose logs -f dbt_app
- docker exec -it dbt_app dbt run


- docker exec -it dbt_app dbt docs generate
- docker exec -it dbt_app dbt docs serve