WITH source as (
    SELECT *
    FROM {{ source('raw', 'product_category_name_translation') }}
)
SELECT
    REPLACE(UPPER(TRIM(product_category_name)), '_', ' ') as category_name_portuguese,
    REPLACE(UPPER(TRIM(product_category_name_english)), '_', ' ') as category_name_english
FROM source