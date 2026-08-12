-- Margin by acquisition channel (revenue - COGS)

SELECT
    ch.channel_name AS acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(o.order_id) AS orders,
    ROUND(SUM(CASE WHEN o.is_size_exchange = 0 THEN o.gross_revenue ELSE 0 END), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN o.is_size_exchange = 0 THEN o.cogs ELSE 0 END), 2) AS cogs,
    ROUND(
        SUM(CASE WHEN o.is_size_exchange = 0 THEN o.gross_revenue - o.cogs ELSE 0 END),
        2
    ) AS gross_margin_dollars,
    ROUND(
        100.0 * SUM(CASE WHEN o.is_size_exchange = 0 THEN o.gross_revenue - o.cogs ELSE 0 END)
        / NULLIF(SUM(CASE WHEN o.is_size_exchange = 0 THEN o.gross_revenue ELSE 0 END), 0),
        1
    ) AS gross_margin_pct
FROM customers c
JOIN marketing_channels ch
  ON ch.channel_id = c.acquisition_channel_id
JOIN orders o
  ON o.customer_id = c.customer_id
GROUP BY ch.channel_name
ORDER BY gross_margin_dollars DESC;
