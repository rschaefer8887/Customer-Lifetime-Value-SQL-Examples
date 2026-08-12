-- Paid Social customers: buyer-file vs acquisition subtypes
-- Shows acquisition purity within the Paid Social marketing channel

WITH paid_social_customers AS (
    SELECT
        c.customer_id,
        c.first_order_date,
        c.paid_social_subtype AS meta_bucket,
        ch.channel_name
    FROM customers c
    JOIN marketing_channels ch
      ON ch.channel_id = c.acquisition_channel_id
    WHERE ch.channel_code = 'paid_social'
      AND c.paid_social_subtype IN ('buyer_file', 'acquisition')
),
meta_orders AS (
    SELECT
        p.meta_bucket,
        o.order_id,
        o.customer_id,
        CAST(o.order_date AS DATE) AS order_date,
        o.gross_revenue,
        p.first_order_date
    FROM paid_social_customers p
    JOIN orders o ON o.customer_id = p.customer_id
    WHERE o.is_size_exchange = 0
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
