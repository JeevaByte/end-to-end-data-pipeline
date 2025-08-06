-- Snowflake Database Setup Script
-- Run this script to set up the complete Snowflake environment for the manufacturing data pipeline

-- =============================================================================
-- WAREHOUSE CONFIGURATION
-- =============================================================================

-- Create warehouses for different workloads
CREATE OR REPLACE WAREHOUSE COMPUTE_WH
WITH 
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300  -- 5 minutes
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'Primary warehouse for data processing and analytics';

CREATE OR REPLACE WAREHOUSE LOADING_WH
WITH 
    WAREHOUSE_SIZE = 'LARGE'
    AUTO_SUSPEND = 60   -- 1 minute
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'Dedicated warehouse for data loading operations';

CREATE OR REPLACE WAREHOUSE ANALYTICS_WH
WITH 
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 600  -- 10 minutes
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    SCALING_POLICY = 'ECONOMY'
    COMMENT = 'Warehouse for ad-hoc analytics and reporting';

-- =============================================================================
-- DATABASE AND SCHEMA SETUP
-- =============================================================================

-- Create main database
CREATE OR REPLACE DATABASE MANUFACTURING_DW
COMMENT = 'Manufacturing Data Warehouse - Central repository for all manufacturing data';

USE DATABASE MANUFACTURING_DW;

-- Create schemas for different data layers
CREATE OR REPLACE SCHEMA RAW
COMMENT = 'Raw data directly from source systems (Bronze layer equivalent)';

CREATE OR REPLACE SCHEMA STAGING
COMMENT = 'Intermediate staging area for data transformations';

CREATE OR REPLACE SCHEMA CLEAN
COMMENT = 'Cleaned and validated data (Silver layer equivalent)';

CREATE OR REPLACE SCHEMA MART
COMMENT = 'Business-ready data marts and aggregations (Gold layer equivalent)';

CREATE OR REPLACE SCHEMA ARCHIVE
COMMENT = 'Historical data archive for compliance and backup';

CREATE OR REPLACE SCHEMA METADATA
COMMENT = 'Data pipeline metadata, logs, and monitoring information';

-- =============================================================================
-- STORAGE INTEGRATION (for S3 access)
-- =============================================================================

-- Create storage integration for S3 access
CREATE OR REPLACE STORAGE INTEGRATION S3_MANUFACTURING_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/SnowflakeS3AccessRole'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = (
    's3://manufacturing-data-pipeline-dev-us-east-1/',
    's3://manufacturing-data-pipeline-prod-us-east-1/',
    's3://manufacturing-data-pipeline-archive-dev-us-east-1/',
    's3://manufacturing-data-pipeline-archive-prod-us-east-1/'
  )
  COMMENT = 'Integration for accessing manufacturing data in S3 buckets';

-- Get the AWS IAM User ARN and External ID for S3 IAM role trust policy
DESC STORAGE INTEGRATION S3_MANUFACTURING_INTEGRATION;

-- =============================================================================
-- FILE FORMATS
-- =============================================================================

-- CSV file format for sensor data
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = ','
  RECORD_DELIMITER = '\n'
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  ESCAPE = 'NONE'
  ESCAPE_UNENCLOSED_FIELD = '\134'
  DATE_FORMAT = 'YYYY-MM-DD'
  TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
  NULL_IF = ('NULL', 'null', '', '\\N');

-- JSON file format for equipment logs
CREATE OR REPLACE FILE FORMAT JSON_FORMAT
  TYPE = JSON
  COMPRESSION = AUTO
  ENABLE_OCTAL = FALSE
  ALLOW_DUPLICATE = FALSE
  STRIP_OUTER_ARRAY = TRUE
  STRIP_NULL_VALUES = FALSE
  IGNORE_UTF8_ERRORS = FALSE;

-- Parquet file format for processed data
CREATE OR REPLACE FILE FORMAT PARQUET_FORMAT
  TYPE = PARQUET
  COMPRESSION = AUTO;

-- =============================================================================
-- EXTERNAL STAGES
-- =============================================================================

-- Stage for raw sensor data
CREATE OR REPLACE STAGE RAW.SENSOR_DATA_STAGE
  STORAGE_INTEGRATION = S3_MANUFACTURING_INTEGRATION
  URL = 's3://manufacturing-data-pipeline-dev-us-east-1/raw/sensor-data/'
  FILE_FORMAT = CSV_FORMAT
  COMMENT = 'Stage for raw sensor CSV files from S3';

-- Stage for equipment logs
CREATE OR REPLACE STAGE RAW.EQUIPMENT_LOGS_STAGE
  STORAGE_INTEGRATION = S3_MANUFACTURING_INTEGRATION
  URL = 's3://manufacturing-data-pipeline-dev-us-east-1/raw/equipment-logs/'
  FILE_FORMAT = JSON_FORMAT
  COMMENT = 'Stage for equipment log JSON files from S3';

-- Stage for processed data from Databricks
CREATE OR REPLACE STAGE STAGING.PROCESSED_DATA_STAGE
  STORAGE_INTEGRATION = S3_MANUFACTURING_INTEGRATION
  URL = 's3://manufacturing-data-pipeline-dev-us-east-1/processed/'
  FILE_FORMAT = PARQUET_FORMAT
  COMMENT = 'Stage for processed data files from Databricks';

-- =============================================================================
-- RAW TABLES (Bronze Layer)
-- =============================================================================

USE SCHEMA RAW;

-- Raw sensor data table
CREATE OR REPLACE TABLE SENSOR_DATA_RAW (
    LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FILE_NAME STRING,
    SENSOR_ID STRING,
    TIMESTAMP_UTC TIMESTAMP_NTZ,
    TEMPERATURE DECIMAL(10,2),
    HUMIDITY DECIMAL(5,2),
    PRESSURE DECIMAL(10,2),
    VIBRATION_X DECIMAL(10,4),
    VIBRATION_Y DECIMAL(10,4),
    VIBRATION_Z DECIMAL(10,4),
    STATUS STRING,
    QUALITY_SCORE DECIMAL(3,2),
    RAW_DATA VARIANT
) 
COMMENT = 'Raw sensor data from manufacturing equipment';

-- Raw equipment logs table
CREATE OR REPLACE TABLE EQUIPMENT_LOGS_RAW (
    LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FILE_NAME STRING,
    EQUIPMENT_ID STRING,
    LOG_TIMESTAMP TIMESTAMP_NTZ,
    LOG_LEVEL STRING,
    MESSAGE STRING,
    ERROR_CODE STRING,
    PARAMETERS VARIANT,
    RAW_JSON VARIANT
)
COMMENT = 'Raw equipment logs and error messages';

-- =============================================================================
-- CLEAN TABLES (Silver Layer)
-- =============================================================================

USE SCHEMA CLEAN;

-- Cleaned sensor data
CREATE OR REPLACE TABLE SENSOR_DATA_CLEAN (
    SENSOR_ID STRING NOT NULL,
    EQUIPMENT_ID STRING,
    LOCATION STRING,
    TIMESTAMP_UTC TIMESTAMP_NTZ NOT NULL,
    TEMPERATURE DECIMAL(10,2),
    HUMIDITY DECIMAL(5,2),
    PRESSURE DECIMAL(10,2),
    VIBRATION_X DECIMAL(10,4),
    VIBRATION_Y DECIMAL(10,4),
    VIBRATION_Z DECIMAL(10,4),
    STATUS STRING,
    QUALITY_SCORE DECIMAL(3,2),
    IS_ANOMALY BOOLEAN DEFAULT FALSE,
    DATA_QUALITY_FLAGS STRING,
    PROCESSED_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_SENSOR_DATA PRIMARY KEY (SENSOR_ID, TIMESTAMP_UTC)
)
CLUSTER BY (SENSOR_ID, TIMESTAMP_UTC)
COMMENT = 'Cleaned and validated sensor data';

-- Cleaned equipment data
CREATE OR REPLACE TABLE EQUIPMENT_MASTER (
    EQUIPMENT_ID STRING PRIMARY KEY,
    EQUIPMENT_NAME STRING,
    EQUIPMENT_TYPE STRING,
    MANUFACTURER STRING,
    MODEL STRING,
    INSTALLATION_DATE DATE,
    LOCATION STRING,
    DEPARTMENT STRING,
    STATUS STRING,
    SPECIFICATIONS VARIANT,
    CREATED_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Master data for manufacturing equipment';

-- =============================================================================
-- MART TABLES (Gold Layer)
-- =============================================================================

USE SCHEMA MART;

-- Hourly sensor aggregates
CREATE OR REPLACE TABLE SENSOR_HOURLY_AGG (
    SENSOR_ID STRING,
    EQUIPMENT_ID STRING,
    HOUR_TIMESTAMP TIMESTAMP_NTZ,
    AVG_TEMPERATURE DECIMAL(10,2),
    MIN_TEMPERATURE DECIMAL(10,2),
    MAX_TEMPERATURE DECIMAL(10,2),
    AVG_HUMIDITY DECIMAL(5,2),
    AVG_PRESSURE DECIMAL(10,2),
    AVG_VIBRATION DECIMAL(10,4),
    ANOMALY_COUNT INTEGER,
    TOTAL_READINGS INTEGER,
    QUALITY_PERCENTAGE DECIMAL(5,2),
    CREATED_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_HOURLY_AGG PRIMARY KEY (SENSOR_ID, HOUR_TIMESTAMP)
)
CLUSTER BY (SENSOR_ID, HOUR_TIMESTAMP)
COMMENT = 'Hourly aggregated sensor metrics for analytics';

-- Daily equipment summary
CREATE OR REPLACE TABLE EQUIPMENT_DAILY_SUMMARY (
    EQUIPMENT_ID STRING,
    DATE_PARTITION DATE,
    TOTAL_RUNTIME_HOURS DECIMAL(5,2),
    DOWNTIME_HOURS DECIMAL(5,2),
    EFFICIENCY_PERCENTAGE DECIMAL(5,2),
    ERROR_COUNT INTEGER,
    WARNING_COUNT INTEGER,
    MAINTENANCE_REQUIRED BOOLEAN,
    PREDICTED_FAILURE_RISK DECIMAL(3,2),
    CREATED_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_DAILY_SUMMARY PRIMARY KEY (EQUIPMENT_ID, DATE_PARTITION)
)
CLUSTER BY (EQUIPMENT_ID, DATE_PARTITION)
COMMENT = 'Daily operational summary for each equipment';

-- =============================================================================
-- METADATA TABLES
-- =============================================================================

USE SCHEMA METADATA;

-- Data pipeline runs tracking
CREATE OR REPLACE TABLE PIPELINE_RUNS (
    RUN_ID STRING PRIMARY KEY,
    PIPELINE_NAME STRING,
    START_TIMESTAMP TIMESTAMP_NTZ,
    END_TIMESTAMP TIMESTAMP_NTZ,
    STATUS STRING,
    RECORDS_PROCESSED INTEGER,
    ERRORS_COUNT INTEGER,
    EXECUTION_TIME_SECONDS INTEGER,
    CONFIGURATION VARIANT,
    ERROR_DETAILS STRING
)
COMMENT = 'Tracking table for data pipeline execution';

-- Data quality metrics
CREATE OR REPLACE TABLE DATA_QUALITY_METRICS (
    METRIC_ID STRING PRIMARY KEY,
    TABLE_NAME STRING,
    COLUMN_NAME STRING,
    METRIC_TYPE STRING,
    METRIC_VALUE DECIMAL(15,4),
    THRESHOLD_VALUE DECIMAL(15,4),
    STATUS STRING,
    MEASURED_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Data quality metrics and monitoring';

-- =============================================================================
-- VIEWS FOR ANALYTICS
-- =============================================================================

USE SCHEMA MART;

-- Real-time equipment status view
CREATE OR REPLACE VIEW VW_EQUIPMENT_STATUS AS
SELECT 
    e.EQUIPMENT_ID,
    e.EQUIPMENT_NAME,
    e.LOCATION,
    e.STATUS as EQUIPMENT_STATUS,
    s.TIMESTAMP_UTC as LAST_READING_TIME,
    s.TEMPERATURE,
    s.HUMIDITY,
    s.PRESSURE,
    s.QUALITY_SCORE,
    s.IS_ANOMALY,
    CASE 
        WHEN s.IS_ANOMALY = TRUE THEN 'ALERT'
        WHEN s.QUALITY_SCORE < 0.8 THEN 'WARNING'
        ELSE 'NORMAL'
    END as ALERT_LEVEL
FROM CLEAN.EQUIPMENT_MASTER e
LEFT JOIN CLEAN.SENSOR_DATA_CLEAN s ON e.EQUIPMENT_ID = s.EQUIPMENT_ID
QUALIFY ROW_NUMBER() OVER (PARTITION BY e.EQUIPMENT_ID ORDER BY s.TIMESTAMP_UTC DESC) = 1;

-- Equipment efficiency trends
CREATE OR REPLACE VIEW VW_EQUIPMENT_EFFICIENCY_TREND AS
SELECT 
    EQUIPMENT_ID,
    DATE_PARTITION,
    EFFICIENCY_PERCENTAGE,
    LAG(EFFICIENCY_PERCENTAGE, 1) OVER (PARTITION BY EQUIPMENT_ID ORDER BY DATE_PARTITION) as PREV_DAY_EFFICIENCY,
    EFFICIENCY_PERCENTAGE - LAG(EFFICIENCY_PERCENTAGE, 1) OVER (PARTITION BY EQUIPMENT_ID ORDER BY DATE_PARTITION) as EFFICIENCY_CHANGE,
    AVG(EFFICIENCY_PERCENTAGE) OVER (PARTITION BY EQUIPMENT_ID ORDER BY DATE_PARTITION ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as WEEK_AVG_EFFICIENCY
FROM EQUIPMENT_DAILY_SUMMARY
ORDER BY EQUIPMENT_ID, DATE_PARTITION;

-- =============================================================================
-- STORED PROCEDURES
-- =============================================================================

-- Procedure to refresh hourly aggregates
CREATE OR REPLACE PROCEDURE SP_REFRESH_HOURLY_AGGREGATES()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Delete existing data for the current hour
    DELETE FROM MART.SENSOR_HOURLY_AGG 
    WHERE HOUR_TIMESTAMP = DATE_TRUNC('HOUR', CURRENT_TIMESTAMP());
    
    -- Insert new aggregated data
    INSERT INTO MART.SENSOR_HOURLY_AGG
    SELECT 
        SENSOR_ID,
        EQUIPMENT_ID,
        DATE_TRUNC('HOUR', TIMESTAMP_UTC) as HOUR_TIMESTAMP,
        AVG(TEMPERATURE) as AVG_TEMPERATURE,
        MIN(TEMPERATURE) as MIN_TEMPERATURE,
        MAX(TEMPERATURE) as MAX_TEMPERATURE,
        AVG(HUMIDITY) as AVG_HUMIDITY,
        AVG(PRESSURE) as AVG_PRESSURE,
        AVG((VIBRATION_X + VIBRATION_Y + VIBRATION_Z) / 3) as AVG_VIBRATION,
        SUM(CASE WHEN IS_ANOMALY = TRUE THEN 1 ELSE 0 END) as ANOMALY_COUNT,
        COUNT(*) as TOTAL_READINGS,
        AVG(QUALITY_SCORE) * 100 as QUALITY_PERCENTAGE,
        CURRENT_TIMESTAMP() as CREATED_TIMESTAMP
    FROM CLEAN.SENSOR_DATA_CLEAN
    WHERE TIMESTAMP_UTC >= DATE_TRUNC('HOUR', CURRENT_TIMESTAMP()) - INTERVAL '1 HOUR'
      AND TIMESTAMP_UTC < DATE_TRUNC('HOUR', CURRENT_TIMESTAMP()) + INTERVAL '1 HOUR'
    GROUP BY SENSOR_ID, EQUIPMENT_ID, DATE_TRUNC('HOUR', TIMESTAMP_UTC);
    
    RETURN 'Hourly aggregates refreshed successfully';
END;
$$;

-- =============================================================================
-- TASKS FOR AUTOMATION
-- =============================================================================

-- Create task to refresh hourly aggregates
CREATE OR REPLACE TASK TASK_REFRESH_HOURLY_AGG
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 0 * * * * UTC'  -- Every hour
    COMMENT = 'Refresh hourly sensor aggregates'
AS
    CALL SP_REFRESH_HOURLY_AGGREGATES();

-- Start the task
ALTER TASK TASK_REFRESH_HOURLY_AGG RESUME;

-- =============================================================================
-- GRANTS AND PERMISSIONS SETUP
-- =============================================================================

-- Grant usage on database
GRANT USAGE ON DATABASE MANUFACTURING_DW TO ROLE PUBLIC;

-- Grant usage on schemas
GRANT USAGE ON SCHEMA MANUFACTURING_DW.RAW TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA MANUFACTURING_DW.CLEAN TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA MANUFACTURING_DW.MART TO ROLE PUBLIC;

-- Grant select on views
GRANT SELECT ON ALL VIEWS IN SCHEMA MANUFACTURING_DW.MART TO ROLE PUBLIC;

-- =============================================================================
-- VALIDATION QUERIES
-- =============================================================================

-- Check if all objects were created successfully
SELECT 'Warehouses' as OBJECT_TYPE, COUNT(*) as COUNT FROM INFORMATION_SCHEMA.WAREHOUSES WHERE WAREHOUSE_NAME LIKE '%WH'
UNION ALL
SELECT 'Databases', COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'MANUFACTURING_DW'
UNION ALL
SELECT 'Schemas', COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME IN ('RAW', 'STAGING', 'CLEAN', 'MART', 'ARCHIVE', 'METADATA')
UNION ALL
SELECT 'Tables', COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA IN ('RAW', 'CLEAN', 'MART', 'METADATA')
UNION ALL
SELECT 'Views', COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'MART'
UNION ALL
SELECT 'File Formats', COUNT(*) FROM INFORMATION_SCHEMA.FILE_FORMATS WHERE FILE_FORMAT_NAME IN ('CSV_FORMAT', 'JSON_FORMAT', 'PARQUET_FORMAT')
UNION ALL
SELECT 'Stages', COUNT(*) FROM INFORMATION_SCHEMA.STAGES WHERE STAGE_SCHEMA IN ('RAW', 'STAGING');

-- Test data loading (run after setting up external stages)
-- LIST @RAW.SENSOR_DATA_STAGE;
-- LIST @RAW.EQUIPMENT_LOGS_STAGE;

COMMIT;
