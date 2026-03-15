-- Create a new schema:
USE DATABASE sales_analytics;

CREATE SCHEMA IF NOT EXISTS monitoring;




-- 1️ Monitor Warehouse Load (Compute Pressure)
-- This shows how busy your warehouse is.
-- Snowflake provides the WAREHOUSE_LOAD_HISTORY function which returns query load metrics for a warehouse within a time range.
-- Warehouse Load Monitoring View
CREATE OR REPLACE VIEW monitoring.vw_warehouse_load AS
SELECT
    start_time,
    end_time,
    warehouse_name,
    avg_running,
    avg_queued_load,
    avg_queued_provisioning,
    avg_blocked
FROM TABLE(
    INFORMATION_SCHEMA.WAREHOUSE_LOAD_HISTORY(
        DATE_RANGE_START => DATEADD('day', -7, CURRENT_TIMESTAMP()),
        DATE_RANGE_END => CURRENT_TIMESTAMP(),
        WAREHOUSE_NAME => 'INGEST_WH'
    )
);

-- 2️⃣ Monitor Query Execution
-- Snowflake exposes query activity through QUERY_HISTORY which tracks queries by time, user, and warehouse.
-- Query Monitoring View
CREATE OR REPLACE VIEW monitoring.vw_query_performance AS
SELECT
    query_id,
    user_name,
    warehouse_name,
    database_name,
    schema_name,
    query_text,
    execution_status,
    total_elapsed_time/1000 AS execution_seconds,
    rows_produced,
    bytes_scanned,
    start_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP());

-- 3️⃣ Detect Long-Running Queries
-- Important for performance monitoring.
CREATE OR REPLACE VIEW monitoring.vw_long_running_queries AS
SELECT
    query_id,
    user_name,
    warehouse_name,
    total_elapsed_time/1000 AS execution_seconds,
    query_text,
    start_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE total_elapsed_time > 60000
ORDER BY execution_seconds DESC;

-- 4️⃣ Monitor Failed Queries
-- This helps detect pipeline failures.
CREATE OR REPLACE VIEW monitoring.vw_failed_queries AS
SELECT
    query_id,
    user_name,
    warehouse_name,
    execution_status,
    error_message,
    start_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE execution_status != 'SUCCESS'
ORDER BY start_time DESC;


-- 5️⃣ Monitor Credit Usage (Cost Monitoring)
-- Snowflake compute costs come from warehouse credits.
CREATE OR REPLACE VIEW monitoring.vw_credit_usage AS
SELECT
    warehouse_name,
    start_time,
    end_time,
    credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP());


-- 6️⃣ Detect Expensive Queries
-- Queries scanning large data.
CREATE OR REPLACE VIEW monitoring.vw_expensive_queries AS
SELECT
    query_id,
    warehouse_name,
    bytes_scanned/1024/1024/1024 AS gb_scanned,
    total_elapsed_time/1000 AS execution_seconds,
    query_text
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE bytes_scanned > 1000000000
ORDER BY gb_scanned DESC;


-- 7️⃣ Monitor Pipeline Tables
-- Check row counts in your pipeline layers.
CREATE OR REPLACE VIEW monitoring.vw_pipeline_row_counts AS
SELECT 'raw.customers' AS table_name, COUNT(*) AS row_count FROM raw.customers
UNION ALL
SELECT 'raw.products', COUNT(*) FROM raw.products
UNION ALL
SELECT 'raw.transactions', COUNT(*) FROM raw.transactions
UNION ALL
SELECT 'production.fact_sales', COUNT(*) FROM production.fact_sales;












-- 1️⃣ Warehouse Load Monitoring
-- Shows how busy the compute warehouse is and whether queries are waiting in queue.
SELECT
    warehouse_name,
    start_time,
    avg_running,
    avg_queued_load,
    avg_blocked
FROM monitoring.vw_warehouse_load
ORDER BY start_time DESC
LIMIT 20;
-- What this reveals
-- Active queries running in the warehouse
-- Queries waiting due to overload
-- Potential warehouse scaling issues

-- 2️⃣ Query Performance Monitoring
-- Displays recent queries executed in the system.
SELECT
    query_id,
    user_name,
    warehouse_name,
    execution_seconds,
    bytes_scanned,
    rows_produced,
    execution_status
FROM monitoring.vw_query_performance
ORDER BY execution_seconds DESC
LIMIT 20;
-- What this reveals
-- Query runtime
-- Data scanned by queries
-- Query success or failure

-- 3️⃣ Long Running Queries
-- Identifies queries that exceed the performance threshold.
SELECT
    query_id,
    user_name,
    warehouse_name,
    execution_seconds,
    query_text,
    start_time
FROM monitoring.vw_long_running_queries
ORDER BY execution_seconds DESC
LIMIT 10;
-- What this reveals
-- Slow queries affecting system performance
-- Potential inefficient SQL queries

-- 4️⃣ Failed Query Monitoring
-- Shows queries that failed during execution.
SELECT
    query_id,
    user_name,
    warehouse_name,
    execution_status,
    error_message,
    start_time
FROM monitoring.vw_failed_queries
ORDER BY start_time DESC
LIMIT 10;
-- What this reveals
-- Pipeline failures
-- SQL errors
-- System issues during execution

-- 5️⃣ Warehouse Credit Usage
-- Displays compute credits consumed by each warehouse.
SELECT
    warehouse_name,
    SUM(credits_used) AS total_credits_used
FROM monitoring.vw_credit_usage
GROUP BY warehouse_name
ORDER BY total_credits_used DESC;
-- What this reveals
-- Compute cost usage
-- Warehouse cost distribution
-- Potential cost optimization opportunities

-- 6️⃣ Expensive Queries Detection
-- Shows queries scanning large amounts of data.
SELECT
    query_id,
    warehouse_name,
    gb_scanned,
    execution_seconds
FROM monitoring.vw_expensive_queries
ORDER BY gb_scanned DESC
LIMIT 10;
-- What this reveals
-- Queries scanning excessive data
-- Inefficient filtering or joins

-- 7️⃣ Pipeline Row Count Monitoring
-- Displays row counts across pipeline layers.
SELECT *
FROM monitoring.vw_pipeline_row_counts;
-- What this reveals
-- Data consistency between layers
-- Successful data ingestion and transformation



-- 8️⃣ Daily Credit Usage Trend
-- Shows credit usage trend over time.

SELECT
    DATE(start_time) AS usage_date,
    SUM(credits_used) AS daily_credits_used
FROM monitoring.vw_credit_usage
GROUP BY usage_date
ORDER BY usage_date DESC;
-- What this reveals
-- Daily compute consumption
-- Cost spikes or unusual usage patterns