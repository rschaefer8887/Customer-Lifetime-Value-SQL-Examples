-- Data quality / anomaly checks used before trusting channel metrics.

SELECT 'duplicate_customers' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT customer_id
    FROM customers
    GROUP BY 1
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'orphan_orders', COUNT(*)
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
  AND o.customer_id < 90000

UNION ALL

SELECT
    'size_exchange_order_share_pct',
    ROUND(100.0 * AVG(is_size_exchange), 2)
FROM orders

UNION ALL

-- Customers whose acquisition_channel_id is not in the dimension table
SELECT 'customers_missing_channel_dim', COUNT(*)
FROM customers c
LEFT JOIN marketing_channels ch
  ON ch.channel_id = c.acquisition_channel_id
WHERE ch.channel_id IS NULL

UNION ALL

-- Orders pointing at an unknown order_channel_id
SELECT 'orders_missing_channel_dim', COUNT(*)
FROM orders o
LEFT JOIN marketing_channels ch
  ON ch.channel_id = o.order_channel_id
WHERE ch.channel_id IS NULL

UNION ALL

-- Customers whose acquisition_month_id is not in months
SELECT 'customers_missing_month_dim', COUNT(*)
FROM customers c
LEFT JOIN months m
  ON m.month_id = c.acquisition_month_id
WHERE m.month_id IS NULL;
