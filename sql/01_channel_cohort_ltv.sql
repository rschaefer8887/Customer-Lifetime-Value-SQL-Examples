-- Cohorts by marketing channel + acquisition month (using months dimension)

WITH customer_value AS (
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
    m.month_label AS cohort_month,
    m.month_start,
    ch.channel_name AS acquisition_channel,
    COUNT(c.customer_id) AS customers,
    ROUND(AVG(v.ltv_revenue), 2) AS avg_ltv,
    ROUND(AVG(v.order_count), 2) AS avg_orders,
    ROUND(100.0 * AVG(CASE WHEN v.rebuy_orders > 0 THEN 1.0 ELSE 0.0 END), 1) AS pct_rebuy
FROM months m
CROSS JOIN marketing_channels ch
LEFT JOIN customers c
  ON c.acquisition_month_id = m.month_id
 AND c.acquisition_channel_id = ch.channel_id
LEFT JOIN customer_value v
  ON v.customer_id = c.customer_id
GROUP BY m.month_label, m.month_start, ch.channel_name
HAVING COUNT(c.customer_id) > 0
ORDER BY m.month_start, avg_ltv DESC;
