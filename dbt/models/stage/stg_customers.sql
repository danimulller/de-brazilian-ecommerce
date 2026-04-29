WITH source as (
    SELECT *
    FROM {{ source('raw', 'olist_customers_dataset') }}
)
SELECT customer_id,
    UPPER(TRIM(customer_city)) as customer_city,
    UPPER(TRIM(customer_state))::VARCHAR(2) as customer_state
FROM source