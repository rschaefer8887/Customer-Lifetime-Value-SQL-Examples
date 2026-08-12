-- Split Meta into buyer-file vs acquisition analytical channels
-- Audits whether "acquisition" spend is actually producing new customers.

WITH meta_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        CAST(o.order_date AS DATE) AS order_date,
        o.gross_revenue,
        c.first_order_date,
        c.acquisition_channel,
        CASE
            WHEN c.acquisition_channel = 'meta_buyer_file' THEN 'buyer_file'
            WHEN c.acquisition_channel = 'meta_acquisition' THEN 'acquisition'
            ELSE 'other'
        END AS meta_bucket
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE c.acquisition_channel IN ('meta_buyer_file', 'meta_acquisition')
      AND o.is_size_exchange = 0
),
new_vs_existing AS (
    SELECT
        meta_bucket,
        COUNT(*) AS orders,
        COUNT(*) FILTER (
            WHERE order_date = CAST(first_order_date AS DATE)
        ) AS first_purchase_orders,
        COUNT(*) FILTER (
            WHERE order_date > CAST(first_order_date AS DATE)
        ) AS existing_customer_orders,
        ROUND(SUM(gross_revenue), 2) AS revenue
    FROM meta_orders
    GROUP BY 1
),
spend AS (
    SELECT
        campaign_type AS meta_bucket,
        ROUND(SUM(spend), 2) AS spend
    FROM meta_spend
    GROUP BY 1
)
SELECT
    n.meta_bucket,
    s.spend,
    n.orders,
    n.first_purchase_orders,
    n.existing_customer_orders,
    n.revenue,
    ROUND(n.revenue / NULLIF(s.spend, 0), 2) AS roas,
    ROUND(
        100.0 * n.existing_customer_orders / NULLIF(n.orders, 0),
        1
    ) AS pct_orders_from_existing_customers
FROM new_vs_existing n
LEFT JOIN spend s ON s.meta_bucket = n.meta_bucket
ORDER BY n.meta_bucket;
