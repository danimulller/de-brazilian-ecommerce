WITH source as (
    SELECT *
    FROM {{ source('raw', 'olist_products_dataset') }}
)
SELECT product_id,
    REPLACE(UPPER(TRIM(product_category_name)), '_', ' ') as category_name,
    product_weight_g::NUMERIC(10,2) as weight_g,
    product_length_cm::NUMERIC(10,2) as length_cm,
    product_height_cm::NUMERIC(10,2) as height_cm,
    product_width_cm::NUMERIC(10,2) as width_cm
FROM source