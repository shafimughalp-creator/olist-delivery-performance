-- Olist Delivery Performance — Quality Checks
-- Run these before trusting any KPI.

-- Row counts
SELECT 'orders'          AS table_name, COUNT(*) FROM orders
UNION ALL
SELECT 'customers',       COUNT(*) FROM customers
UNION ALL
SELECT 'order_items',     COUNT(*) FROM order_items
UNION ALL
SELECT 'order_reviews',   COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products',        COUNT(*) FROM products
UNION ALL
SELECT 'sellers',         COUNT(*) FROM sellers
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;

-- Control total (must be 13,591,643.70)
SELECT ROUND(SUM(price), 2) AS total_price FROM order_items;

-- Primary key uniqueness — all should return 0 rows
SELECT order_id, COUNT(*) FROM orders          GROUP BY order_id HAVING COUNT(*) > 1;
SELECT customer_id, COUNT(*) FROM customers    GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT product_id, COUNT(*) FROM products      GROUP BY product_id HAVING COUNT(*) > 1;
SELECT seller_id, COUNT(*) FROM sellers        GROUP BY seller_id HAVING COUNT(*) > 1;
SELECT order_id, COUNT(*) FROM order_reviews   GROUP BY order_id HAVING COUNT(*) > 1;

-- Anomaly flag counts
SELECT
    SUM(sequence_anomaly)        AS seq_anom,
    SUM(sequence_anomaly_severe) AS seq_severe,
    SUM(impossible_delivery)     AS impossible,
    SUM(migration_artifact)      AS migration
FROM orders;
