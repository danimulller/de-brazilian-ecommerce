WITH source as (
    SELECT *
    FROM {{ source('raw', 'olist_sellers_dataset') }}
)
SELECT seller_id,
    UPPER(TRIM(seller_city)) as seller_city,
    UPPER(TRIM(seller_state))::VARCHAR(2) as seller_state
FROM source