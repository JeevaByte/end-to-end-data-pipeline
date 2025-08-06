# Data Ingestion Framework

## 🚀 Overview

This module handles the ingestion of manufacturing sensor data from AWS S3 into Databricks Delta Lake using Auto Loader for streaming and batch processing.

## 📁 Directory Structure

```
03-data-ingestion/
├── auto-loader/           # Databricks Auto Loader configurations
├── batch-ingestion/       # Batch processing scripts
├── streaming/             # Real-time streaming ingestion
├── data-generators/       # Sample data generation scripts
├── monitoring/            # Ingestion monitoring and alerting
├── tests/                 # Unit and integration tests
└── config/                # Configuration files
```

## 🔄 Ingestion Patterns

### 1. Auto Loader (Recommended)
- **Use Case**: Continuously ingest new files as they arrive in S3
- **Benefits**: Automatic schema evolution, exactly-once processing
- **Best For**: Real-time and near-real-time ingestion

### 2. Batch Processing
- **Use Case**: Scheduled bulk ingestion of historical data
- **Benefits**: Better for large file processing, easier debugging
- **Best For**: Initial data loads, backfill operations

### 3. Streaming
- **Use Case**: Real-time processing of high-velocity data
- **Benefits**: Low latency, real-time insights
- **Best For**: Critical monitoring and alerting

## 📊 Data Sources

### Manufacturing Sensor Data
- **Format**: CSV, JSON
- **Volume**: 1-10 GB per day
- **Frequency**: Every 5-15 minutes
- **Schema**: Semi-structured with sensor readings

### Equipment Logs
- **Format**: JSON
- **Volume**: 100-500 MB per day
- **Frequency**: Continuous
- **Schema**: Structured log entries

### Quality Metrics
- **Format**: Parquet, CSV
- **Volume**: 50-200 MB per day
- **Frequency**: Hourly
- **Schema**: Structured measurements

## 🛠️ Implementation Guide

### Step 1: Set Up Auto Loader
```python
# Configure Auto Loader for sensor data
sensor_stream = (spark.readStream
    .format("cloudFiles")
    .option("cloudFiles.format", "csv")
    .option("cloudFiles.schemaLocation", "/tmp/schema_sensor")
    .option("cloudFiles.schemaEvolutionMode", "addNewColumns")
    .option("header", "true")
    .load("s3://manufacturing-data-pipeline-dev-us-east-1/raw/sensor-data/")
)
```

### Step 2: Configure Schema Evolution
```python
# Define expected schema for validation
expected_schema = StructType([
    StructField("sensor_id", StringType(), True),
    StructField("timestamp", TimestampType(), True),
    StructField("temperature", DoubleType(), True),
    StructField("humidity", DoubleType(), True),
    StructField("pressure", DoubleType(), True)
])
```

### Step 3: Set Up Monitoring
```python
# Monitor ingestion progress
query = (sensor_stream.writeStream
    .format("delta")
    .option("checkpointLocation", "/tmp/checkpoint_sensor")
    .option("mergeSchema", "true")
    .outputMode("append")
    .table("manufacturing_bronze.sensor_data")
    .awaitTermination()
)
```

## 📈 Performance Optimization

### File Size Optimization
- **Target**: 128 MB - 1 GB per file
- **Strategy**: Configure appropriate partitioning
- **Monitoring**: Track small file counts

### Parallelism
- **Auto Loader**: Automatically scales based on data volume
- **Batch Processing**: Configure `maxFilesPerTrigger` for control
- **Resource Allocation**: Right-size clusters for workload

### Checkpointing
- **Location**: S3 for durability
- **Frequency**: Configure based on data velocity
- **Cleanup**: Implement automated checkpoint management

## 🔍 Data Quality Checks

### Schema Validation
- Enforce required columns
- Validate data types
- Check for schema drift

### Content Validation
- Range checks for sensor values
- Timestamp validation
- Duplicate detection

### Quality Metrics
- Record counts and processing rates
- Error rates and failure patterns
- Data freshness metrics

## 📊 Monitoring and Alerting

### Key Metrics
- **Ingestion Rate**: Records per second
- **Latency**: End-to-end processing time
- **Error Rate**: Failed records percentage
- **File Processing**: Files processed vs. failed

### Alerting Rules
- Ingestion stops for > 15 minutes
- Error rate > 5%
- File processing backlog > 1 hour
- Schema evolution detected

## 🧪 Testing Strategy

### Unit Tests
- Schema validation functions
- Data transformation logic
- Error handling scenarios

### Integration Tests
- End-to-end ingestion flow
- Schema evolution handling
- Failure recovery testing

### Performance Tests
- Load testing with sample data
- Scalability validation
- Resource utilization monitoring

## 🔒 Security Considerations

### Access Control
- IAM roles for S3 access
- Databricks workspace permissions
- Secret management for credentials

### Data Encryption
- Encryption in transit (HTTPS/TLS)
- Encryption at rest (S3, Delta Lake)
- Key rotation policies

### Audit Logging
- All ingestion activities logged
- Access patterns monitored
- Compliance reporting available

## 🚨 Troubleshooting Guide

### Common Issues
1. **Schema Evolution Failures**
   - Check schema compatibility
   - Review evolution mode settings
   - Validate data types

2. **Performance Issues**
   - Monitor cluster utilization
   - Check file sizes and partitioning
   - Review Auto Loader configuration

3. **Access Denied Errors**
   - Verify IAM permissions
   - Check S3 bucket policies
   - Validate Databricks workspace access

4. **Data Quality Issues**
   - Review source data formats
   - Check transformation logic
   - Validate schema expectations

### Debug Commands
```python
# Check stream status
display(spark.streams.active)

# View checkpoint information
dbutils.fs.ls("/tmp/checkpoint_sensor")

# Check ingestion metrics
spark.sql("DESCRIBE HISTORY manufacturing_bronze.sensor_data").show()
```

## 📋 Deployment Checklist

Before deploying to production:
- [ ] Schema validation implemented
- [ ] Data quality checks configured
- [ ] Monitoring and alerting set up
- [ ] Error handling tested
- [ ] Performance optimized
- [ ] Security measures in place
- [ ] Documentation updated
- [ ] Team training completed
