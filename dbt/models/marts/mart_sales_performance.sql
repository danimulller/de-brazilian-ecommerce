-- depends_on: {{ ref('stg_orders') }}
-- depends_on: {{ ref('stg_order_items') }}

with orders as (
    select
        order_id,
        customer_id,
        status,
        purchased_at
    from {{ ref('stg_orders') }}
    where status = 'DELIVERED'
),
order_items as (
    select
        order_id,
        product_id,
        price_amount,
        freight_amount
    from {{ ref('stg_order_items') }}
),
products as (
    select
        product_id,
        category_name
    from {{ ref('dim_products') }}
),
customers as (
    select
        customer_id,
        customer_city,
        customer_state
    from {{ ref('dim_customers') }}
),
joined as (
    select
        extract(year FROM orders.purchased_at) as year,
        extract(month FROM orders.purchased_at) as month,
        products.category_name,
        customers.customer_state,
        customers.customer_city,
        orders.order_id,
        order_items.product_id,
        order_items.price_amount,
        order_items.freight_amount
    from orders
    inner join order_items on orders.order_id = order_items.order_id
    inner join products on order_items.product_id = products.product_id
    inner join customers on orders.customer_id = customers.customer_id
),
final as (
    select
        year,
        month,
        category_name,
        customer_state,

        count(distinct order_id) as total_orders,
        count(product_id) as total_items_sold,

        round(sum(price_amount), 2) as total_revenue,
        round(sum(freight_amount), 2) as total_freight,
        round(sum(price_amount + freight_amount), 2) as total_gmv,

        round(sum(price_amount + freight_amount) / nullif(count(distinct order_id), 0), 2) as avg_order_value,
        round(sum(price_amount) / nullif(count(product_id), 0), 2) as avg_item_price,
        round(sum(freight_amount) / nullif(count(product_id), 0), 2) as avg_freight_value
    from joined
    group by year, month, category_name, customer_state
)
select *
from final