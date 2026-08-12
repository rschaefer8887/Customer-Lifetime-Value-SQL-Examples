-- Channel cohort LTV / rebuy
-- Equivalent to joining acquisition source to purchase history and rolling up by cohort + channel.

WITH first_orders AS (
    SELECT
        customer_id,
        acquisition_channel,
        DATE_TRUNC('month', CAST(first_order_date AS DATE)) AS cohort_month
    FROM customers
),
customer_value AS (
    SELECT
        o.customer_id,
        SUM(CASE WHEN o.is_size_exchange = 0 THEN o.gross_revenue ELSE 0 END) AS ltv_revenue,
        COUNT(*) FILTER (WHERE o.is_size_exchange = 0) AS order_count,
        COUNT(*) FILTER (
            WHERE o.is_size_exchange = 0
              AND o.order_date > c.first_order_date
        ) AS rebuy_orders
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    GROUP BY o.customer_id
)
SELECT
    f.cohort_month,
    f.acquisition_channel,
    COUNT(*) AS customers,
    ROUND(AVG(v.ltv_revenue), 2) AS avg_ltv,
    ROUND(AVG(v.order_count), 2) AS avg_orders,
    ROUND(100.0 * AVG(CASE WHEN v.rebuy_orders > 0 THEN 1.0 ELSE 0.0 END), 1) AS pct_rebuy
FROM first_orders f
JOIN customer_value v ON v.customer_id = f.customer_id
GROUP BY 1, 2
ORDER BY 1, avg_ltv DESC;
