-- depends_on: {{ ref('stg_sellers') }}

with sellers as (
    select
        seller_id,
        seller_city,
        seller_state,
        case
            when seller_state in ('SP', 'RJ', 'MG', 'ES') then 'SOUTHEAST'
            when seller_state in ('PR', 'SC', 'RS') then 'SOUTH'
            when seller_state in ('GO', 'MT', 'MS', 'DF') then 'CENTRAL-WEST'
            when seller_state in ('BA', 'PE', 'CE', 'MA', 'PB', 'RN', 'AL', 'SE', 'PI') then 'NORTHEAST'
            when seller_state in ('AM', 'PA', 'RO', 'RR', 'AC', 'AP', 'TO') then 'NORTH'
            else 'UNKNOWN'
        end as seller_region
    from {{ ref('stg_sellers') }}
)
select *
from sellers