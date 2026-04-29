WITH source as (
    SELECT *
    FROM {{ source('raw', 'olist_orders_dataset') }}
)
SELECT order_id,
    customer_id,
    UPPER(TRIM(order_status)) as status,
    order_purchase_timestamp::TIMESTAMP as purchased_at,
    order_approved_at::TIMESTAMP as approved_at,
    order_delivered_carrier_date::TIMESTAMP as delivered_to_carrier_at,
    order_delivered_customer_date::TIMESTAMP as delivered_to_customer_at,
    order_estimated_delivery_date::DATE as estimated_delivery_date
FROM source