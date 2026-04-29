WITH source as (
    SELECT *
    FROM {{ source('raw', 'olist_order_payments_dataset') }}
)
SELECT order_id,
    payment_sequential::INTEGER as payment_sequential,
    REPLACE(UPPER(TRIM(payment_type)), '_', ' ') as payment_type,
    payment_installments::INTEGER as payment_installments,
    payment_value::NUMERIC(10,2) as payment_amount
FROM source