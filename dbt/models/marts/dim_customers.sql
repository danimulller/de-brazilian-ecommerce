-- depends_on: {{ ref('stg_customers') }}

with customers as (
    select
        customer_id,
        customer_city,
        customer_state,
        case
            when customer_state in ('SP', 'RJ', 'MG', 'ES') then 'SOUTHEAST'
            when customer_state in ('PR', 'SC', 'RS') then 'SOUTH'
            when customer_state in ('GO', 'MT', 'MS', 'DF') then 'CENTRAL-WEST'
            when customer_state in ('BA', 'PE', 'CE', 'MA', 'PB', 'RN', 'AL', 'SE', 'PI') then 'NORTHEAST'
            when customer_state in ('AM', 'PA', 'RO', 'RR', 'AC', 'AP', 'TO') then 'NORTH'
            else 'UNKNOWN'
        end as customer_region
    from {{ ref('stg_customers') }}
)
select *
from customers