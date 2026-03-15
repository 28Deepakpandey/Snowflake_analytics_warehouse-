-- Grant Role Access to Warehouse
GRANT USAGE ON WAREHOUSE ingest_wh TO ROLE data_engineer;
GRANT OPERATE ON WAREHOUSE ingest_wh TO ROLE data_engineer;

-- Grant Access to Database
GRANT USAGE ON DATABASE sales_analytics TO ROLE data_engineer;

-- Grant Access to All Schemas
GRANT USAGE ON ALL SCHEMAS IN DATABASE sales_analytics TO ROLE data_engineer;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE sales_analytics TO ROLE data_engineer;

-- Grant Full Privileges on All Objects
-- Tables
GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE sales_analytics TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE sales_analytics TO ROLE data_engineer;

-- Views
GRANT ALL PRIVILEGES ON ALL VIEWS IN DATABASE sales_analytics TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN DATABASE sales_analytics TO ROLE data_engineer;
-- Stages
GRANT ALL PRIVILEGES ON ALL STAGES IN DATABASE sales_analytics TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE STAGES IN DATABASE sales_analytics TO ROLE data_engineer;
-- File Formats
GRANT ALL PRIVILEGES ON ALL FILE FORMATS IN DATABASE sales_analytics TO ROLE data_engineer;
GRANT ALL PRIVILEGES ON FUTURE FILE FORMATS IN DATABASE sales_analytics TO ROLE data_engineer;