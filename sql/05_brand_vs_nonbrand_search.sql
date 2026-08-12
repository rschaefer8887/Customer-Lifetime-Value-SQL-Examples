-- Treat brand vs non-brand paid search as separate channels for acquisition quality.

SELECT
    acquisition_channel,
    COUNT(*) AS customers,
    ROUND(AVG(ltv_revenue), 2) AS avg_ltv,
    ROUND(100.0 * AVG(CASE WHEN rebuy_orders > 0 THEN 1.0 ELSE 0.0 END), 1) AS pct_rebuy
FROM (
    SELECT
        c.customer_id,
        c.acquisition_channel,
        SUM(CASE WHEN o.is_size_exchange = 0 THEN o.gross_revenue ELSE 0 END) AS ltv_revenue,
        COUNT(*) FILTER (
            WHERE o.is_size_exchange = 0
              AND o.order_date > c.first_order_date
        ) AS rebuy_orders
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE c.acquisition_channel IN ('paid_search_brand', 'paid_search_nonbrand')
    GROUP BY 1, 2
) x
GROUP BY 1
ORDER BY avg_ltv DESC;
