# Databricks Workspace Setup Guide

## 🏗️ Databricks Configuration Overview

This guide covers the complete setup of Databricks workspace for the manufacturing data pipeline project.

## 📋 Prerequisites

1. **Databricks Account**: Premium or Enterprise tier recommended
2. **AWS Account**: With appropriate permissions
3. **Databricks CLI**: Installed and configured
4. **AWS CLI**: Configured with appropriate credentials

## 🚀 Workspace Setup Steps

### Step 1: Create Databricks Workspace

#### Option A: Using Databricks Console
1. Log into Databricks account
2. Create new workspace
3. Choose AWS as cloud provider
4. Select region (recommend us-east-1)
5. Configure network settings

#### Option B: Using Terraform (Recommended)
```hcl
# See terraform/databricks.tf for full configuration
resource "databricks_workspace" "manufacturing_workspace" {
  workspace_name = "manufacturing-data-pipeline"
  aws_region     = "us-east-1"
  pricing_tier   = "PREMIUM"
}
```

### Step 2: Configure Unity Catalog (Enterprise Feature)

```bash
# Enable Unity Catalog
databricks unity-catalog metastores create \
  --name "manufacturing_metastore" \
  --storage-root "s3://manufacturing-data-pipeline-unity-catalog" \
  --region "us-east-1"
```

### Step 3: Set Up Clusters

Create clusters using the provided configuration files:

```bash
# Create development cluster
databricks clusters create --json-file cluster-configs/dev-cluster.json

# Create production cluster
databricks clusters create --json-file cluster-configs/prod-cluster.json
```

## 🔧 Cluster Configurations

### Development Cluster
- **Purpose**: Development and testing
- **Size**: 1 driver + 1-2 workers
- **Instance Type**: i3.xlarge
- **Auto-scaling**: Enabled
- **Auto-termination**: 30 minutes

### Production Cluster
- **Purpose**: Production workloads
- **Size**: 1 driver + 2-8 workers
- **Instance Type**: i3.2xlarge
- **Auto-scaling**: Enabled
- **Spot Instances**: 50% for cost optimization

## 📚 Library Management

### Cluster Libraries
Install the following libraries on all clusters:

```json
{
  "libraries": [
    {
      "pypi": {
        "package": "great-expectations==0.17.23"
      }
    },
    {
      "pypi": {
        "package": "snowflake-connector-python==3.6.0"
      }
    },
    {
      "maven": {
        "coordinates": "net.snowflake:snowflake-jdbc:3.14.4"
      }
    },
    {
      "maven": {
        "coordinates": "net.snowflake:spark-snowflake_2.12:2.12.0-spark_3.4"
      }
    }
  ]
}
```

### Python Environment
```bash
# Install on cluster initialization
pip install \
  great-expectations==0.17.23 \
  snowflake-connector-python==3.6.0 \
  pandas==2.1.4 \
  numpy==1.24.3 \
  matplotlib==3.7.2 \
  seaborn==0.12.2
```

## 🔒 Security Configuration

### Service Principal Setup
```bash
# Create service principal for automation
databricks service-principals create \
  --display-name "Manufacturing Pipeline SP" \
  --active

# Grant necessary permissions
databricks permissions object-permissions set \
  --object-type clusters \
  --object-id <cluster-id> \
  --access-control-list '[
    {
      "service_principal_name": "manufacturing-pipeline-sp",
      "permission_level": "CAN_MANAGE"
    }
  ]'
```

### Secret Scopes
```bash
# Create secret scope for credentials
databricks secrets create-scope --scope manufacturing-secrets

# Add Snowflake credentials
databricks secrets put-secret \
  --scope manufacturing-secrets \
  --key snowflake-username \
  --string-value "your-snowflake-username"

databricks secrets put-secret \
  --scope manufacturing-secrets \
  --key snowflake-password \
  --string-value "your-snowflake-password"

# Add AWS credentials (if not using IAM roles)
databricks secrets put-secret \
  --scope manufacturing-secrets \
  --key aws-access-key \
  --string-value "your-aws-access-key"
```

## 🗄️ Delta Lake Configuration

### Database Setup
```sql
-- Create main databases
CREATE DATABASE IF NOT EXISTS manufacturing_bronze
COMMENT 'Raw sensor data and equipment logs'
LOCATION 's3://manufacturing-data-pipeline-dev-us-east-1/delta/bronze/';

CREATE DATABASE IF NOT EXISTS manufacturing_silver
COMMENT 'Cleaned and validated data'
LOCATION 's3://manufacturing-data-pipeline-dev-us-east-1/delta/silver/';

CREATE DATABASE IF NOT EXISTS manufacturing_gold
COMMENT 'Business-ready aggregated data'
LOCATION 's3://manufacturing-data-pipeline-dev-us-east-1/delta/gold/';
```

### Table Optimization
```sql
-- Enable Auto Optimize for better performance
ALTER TABLE manufacturing_silver.sensor_data 
SET TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true'
);
```

## 🔄 Workflow Configuration

### Job Clusters
Configure job clusters for production workloads:

```json
{
  "job_cluster_key": "manufacturing_etl_cluster",
  "new_cluster": {
    "spark_version": "13.3.x-scala2.12",
    "node_type_id": "i3.xlarge",
    "num_workers": 2,
    "autoscale": {
      "min_workers": 1,
      "max_workers": 8
    },
    "aws_attributes": {
      "instance_profile_arn": "arn:aws:iam::123456789012:instance-profile/databricks-instance-profile",
      "first_on_demand": 1,
      "availability": "SPOT_WITH_FALLBACK"
    }
  }
}
```

## 📊 Monitoring Setup

### Cluster Metrics
Enable cluster monitoring:

```json
{
  "cluster_log_conf": {
    "s3": {
      "destination": "s3://manufacturing-data-pipeline-logs-dev-us-east-1/cluster-logs",
      "region": "us-east-1"
    }
  },
  "init_scripts": [
    {
      "s3": {
        "destination": "s3://manufacturing-data-pipeline-dev-us-east-1/init-scripts/monitoring-setup.sh",
        "region": "us-east-1"
      }
    }
  ]
}
```

### MLflow Setup
```python
# Configure MLflow tracking
import mlflow

mlflow.set_tracking_uri("databricks")
mlflow.set_experiment("/Shared/manufacturing-data-pipeline/experiments")
```

## 🧪 Testing the Setup

### Connectivity Test
```python
# Test S3 connectivity
df = spark.read.option("header", "true").csv("s3://manufacturing-data-pipeline-dev-us-east-1/test/")
df.show()

# Test Snowflake connectivity
snowflake_options = {
    "sfUrl": "your-account.snowflakecomputing.com",
    "sfUser": dbutils.secrets.get("manufacturing-secrets", "snowflake-username"),
    "sfPassword": dbutils.secrets.get("manufacturing-secrets", "snowflake-password"),
    "sfDatabase": "MANUFACTURING_DW",
    "sfSchema": "RAW",
    "sfWarehouse": "COMPUTE_WH"
}

df_test = spark.read \
    .format("snowflake") \
    .options(**snowflake_options) \
    .option("dbtable", "INFORMATION_SCHEMA.TABLES") \
    .load()
df_test.show()
```

## 📋 Validation Checklist

After completing the setup:
- [ ] Workspace created and accessible
- [ ] Clusters configured and running
- [ ] Libraries installed successfully
- [ ] Secret scopes created
- [ ] Delta Lake databases created
- [ ] S3 connectivity working
- [ ] Snowflake connectivity working
- [ ] Unity Catalog configured (if using)
- [ ] Monitoring enabled
- [ ] Job clusters configured

## 🔧 Automation Scripts

### Cluster Management
```bash
#!/bin/bash
# manage-clusters.sh

CLUSTER_ID="your-cluster-id"

case $1 in
  start)
    databricks clusters start --cluster-id $CLUSTER_ID
    ;;
  stop)
    databricks clusters delete --cluster-id $CLUSTER_ID
    ;;
  restart)
    databricks clusters restart --cluster-id $CLUSTER_ID
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
    ;;
esac
```

### Library Installation
```bash
#!/bin/bash
# install-libraries.sh

CLUSTER_ID="your-cluster-id"

# Install Python packages
databricks libraries install \
  --cluster-id $CLUSTER_ID \
  --pypi-package great-expectations==0.17.23

databricks libraries install \
  --cluster-id $CLUSTER_ID \
  --pypi-package snowflake-connector-python==3.6.0

# Install Maven packages
databricks libraries install \
  --cluster-id $CLUSTER_ID \
  --maven-coordinates net.snowflake:spark-snowflake_2.12:2.12.0-spark_3.4
```

## 🆘 Troubleshooting

### Common Issues

1. **Cluster Start Failures**
   - Check instance availability in the region
   - Verify IAM permissions
   - Check instance limits

2. **Library Installation Failures**
   - Verify internet connectivity
   - Check library compatibility
   - Review cluster logs

3. **S3 Access Issues**
   - Verify IAM roles and policies
   - Check bucket permissions
   - Validate cross-account trust

4. **Snowflake Connection Issues**
   - Verify credentials in secret scope
   - Check network connectivity
   - Validate Snowflake permissions

### Debug Commands
```bash
# Check cluster status
databricks clusters get --cluster-id <cluster-id>

# View cluster logs
databricks clusters events --cluster-id <cluster-id>

# List installed libraries
databricks libraries cluster-status --cluster-id <cluster-id>

# Test secret scope access
databricks secrets list --scope manufacturing-secrets
```
