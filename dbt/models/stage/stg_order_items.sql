WITH source as (
    SELECT *
    FROM {{ source('raw', 'olist_order_items_dataset') }}
)
SELECT order_item_id,
    order_id,
    product_id,
    seller_id,
    shipping_limit_date::TIMESTAMP as shipping_limit_date,
    price::NUMERIC(10,2) as price_amount,
    freight_value::NUMERIC(10,2) as freight_amount
FROM source