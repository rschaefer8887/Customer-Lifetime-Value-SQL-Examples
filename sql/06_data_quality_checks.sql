-- Data quality / anomaly checks used before trusting channel metrics.

-- 1) Duplicate customer IDs
SELECT 'duplicate_customers' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT customer_id
    FROM customers
    GROUP BY 1
    HAVING COUNT(*) > 1
) d

UNION ALL

-- 2) Orders with no customer record
SELECT 'orphan_orders', COUNT(*)
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
  AND o.customer_id < 90000

UNION ALL

-- 3) Size-exchange share (watch for revenue inflation)
SELECT
    'size_exchange_order_share_pct',
    ROUND(100.0 * AVG(is_size_exchange), 2)
FROM orders

UNION ALL

-- 4) Acquisition channel blank / unexpected
SELECT 'unknown_acquisition_channel', COUNT(*)
FROM customers
WHERE acquisition_channel IS NULL
   OR TRIM(acquisition_channel) = ''

UNION ALL

-- 5) Meta acquisition customers whose first order channel conflicts (simple hygiene)
SELECT 'meta_acq_flagged_for_review', COUNT(*)
FROM customers c
WHERE c.acquisition_channel = 'meta_acquisition'
  AND EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.customer_id = c.customer_id
        AND o.order_date < c.first_order_date
  );
