-- 1️⃣ Optimize Fact Table with Clustering
-- Large fact tables benefit from cluster keys because they reduce data scanning.
-- Your fact table queries often filter by:
-- transaction_date
-- product_id
-- So clustering should be applied on these columns.

ALTER TABLE production.fact_sales
CLUSTER BY (transaction_date, product_id);
-- Why this helps
-- Snowflake stores data in micro-partitions.
-- Clustering organizes these partitions so queries scan less data.
-- Example optimized query:

SELECT
product_id,
SUM(total_amount) AS total_sales
FROM production.fact_sales
WHERE transaction_date >= '2024-01-01'
GROUP BY product_id;

-- Because of clustering, Snowflake only scans relevant partitions.


-- 2 Warehouse Auto-Scaling Optimization
-- To prevent query queues during heavy workloads, configure the warehouse with multi-cluster scaling.
ALTER WAREHOUSE ingest_wh
SET
MIN_CLUSTER_COUNT = 1,
MAX_CLUSTER_COUNT = 3,
SCALING_POLICY = 'STANDARD';
-- Benefits
-- Automatically adds compute clusters
-- Prevents query waiting
-- Improves concurrency

-- 4️⃣ Warehouse Auto Suspend & Resume
-- Auto suspend prevents unnecessary compute cost.

ALTER WAREHOUSE ingest_wh
SET
AUTO_SUSPEND = 60,
AUTO_RESUME = TRUE;

-- Explanation:
-- Setting	Purpose
-- AUTO_SUSPEND = 60	suspend warehouse after 60 seconds idle
-- AUTO_RESUME = TRUE	automatically start when query runs
-- This reduces credit consumption.