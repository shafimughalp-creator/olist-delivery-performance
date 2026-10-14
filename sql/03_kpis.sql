-- Olist Delivery Performance — KPI Queries
-- Each query computes one of the 5 headline business answers.

-- =========== Query 1: Overall on-time rate ===========
SELECT
    COUNT(*)                                     AS total_delivered,
    SUM(CASE WHEN is_late = 0 THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late,
    ROUND(100.0 * SUM(CASE WHEN is_late = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_pct
FROM orders
WHERE is_late IS NOT NULL;

-- =========== Query 2: On-time rate by state (min 200 orders) ===========
SELECT
    c.customer_state AS state,
    COUNT(*)         AS total_orders,
    ROUND(100.0 * SUM(CASE WHEN o.is_late = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_pct
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.is_late IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 200
ORDER BY late_pct DESC;

-- =========== Query 3: Avg delivery_days by category ===========
SELECT
    COALESCE(ct.product_category_name_english,
             p.product_category_name,
             'unknown_category')          AS category,
    COUNT(DISTINCT o.order_id)            AS total_orders,
    ROUND(AVG(o.delivery_days), 2)        AS avg_delivery_days,
    ROUND(AVG(o.lateness_days), 2)        AS avg_lateness_days
FROM orders o
JOIN order_items i ON i.order_id = o.order_id
JOIN products p    ON p.product_id = i.product_id
LEFT JOIN category_translation ct
    ON ct.product_category_name = p.product_category_name
WHERE o.delivery_days IS NOT NULL
  AND o.migration_artifact = 0
GROUP BY category
HAVING COUNT(DISTINCT o.order_id) >= 200
ORDER BY avg_delivery_days DESC;

-- =========== Query 4: Review score late vs on-time ===========
SELECT
    CASE WHEN o.is_late = 1 THEN 'late' ELSE 'on_time' END AS delivery_status,
    COUNT(*)                                                AS n_orders,
    ROUND(AVG(r.review_score), 3)                           AS avg_review_score,
    ROUND(100.0 * SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_1star,
    ROUND(100.0 * SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_5star
FROM orders o
JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.is_late IS NOT NULL
GROUP BY delivery_status
ORDER BY delivery_status;

-- =========== Query 5: Stage durations ===========
SELECT '1_approval'  AS stage, ROUND(AVG(approval_days), 3)  AS avg_days, COUNT(approval_days)  AS n
  FROM orders WHERE approval_days  IS NOT NULL
UNION ALL
SELECT '2_handoff',              ROUND(AVG(handoff_days), 3),                 COUNT(handoff_days)
  FROM orders WHERE handoff_days   IS NOT NULL
UNION ALL
SELECT '3_last_mile',            ROUND(AVG(last_mile_days), 3),               COUNT(last_mile_days)
  FROM orders WHERE last_mile_days IS NOT NULL
ORDER BY avg_days DESC;

-- =========== Bonus: Monthly on-time trend ===========
SELECT
    strftime('%Y-%m', order_purchase_timestamp) AS month,
    COUNT(*)                                     AS orders,
    ROUND(100.0 * SUM(CASE WHEN is_late = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_pct
FROM orders
WHERE is_late IS NOT NULL
  AND order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01'
GROUP BY month
ORDER BY month;
