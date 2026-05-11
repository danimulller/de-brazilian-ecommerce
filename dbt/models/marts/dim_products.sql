-- depends_on: {{ ref('stg_products') }}

WITH products as (
    SELECT *,
        round(length_cm * height_cm * width_cm, 2)  as volume_cm
    FROM {{ ref('stg_products') }}
)
SELECT *, round(weight_g / volume_cm, 2) as density_g_cm
FROM products