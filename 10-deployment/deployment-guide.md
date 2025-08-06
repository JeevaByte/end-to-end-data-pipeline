# Deployment Guide

## 🚀 Complete Deployment Instructions

This guide provides step-by-step instructions to deploy the entire manufacturing data pipeline from scratch.

## 📋 Prerequisites Checklist

Before starting deployment, ensure you have:

### AWS Account Setup
- [ ] AWS account with admin privileges
- [ ] AWS CLI installed and configured
- [ ] Billing alerts configured
- [ ] Service limits reviewed and increased if needed

### Databricks Account Setup  
- [ ] Databricks account (Premium or Enterprise recommended)
- [ ] Databricks CLI installed
- [ ] Workspace region selected (recommend us-east-1)

### Snowflake Account Setup
- [ ] Snowflake account (Standard or higher)
- [ ] SnowSQL CLI installed
- [ ] Account URL and credentials ready

### Development Environment
- [ ] Python 3.8+ installed
- [ ] Git installed and configured
- [ ] VS Code or preferred IDE
- [ ] Virtual environment tools (conda/virtualenv)

## 🎯 Phase-by-Phase Deployment

### Phase 1: Infrastructure Setup (Estimated: 4-6 hours)

#### Step 1.1: AWS Infrastructure
```bash
# Clone the project
git clone <repository-url>
cd Data-Engineer

# Set environment variables
export AWS_REGION=us-east-1
export ENVIRONMENT=dev
export PROJECT_NAME=manufacturing-data-pipeline

# Create S3 buckets
./10-deployment/scripts/setup-aws.sh

# Create IAM roles
aws cloudformation create-stack \
  --stack-name ${PROJECT_NAME}-iam-roles \
  --template-body file://02-infrastructure/aws/cloudformation/iam-roles.yaml \
  --capabilities CAPABILITY_IAM
```

#### Step 1.2: Databricks Workspace
```bash
# Configure Databricks CLI
databricks configure --token

# Create development cluster
databricks clusters create --json-file 02-infrastructure/databricks/cluster-config.json

# Set up secret scope
databricks secrets create-scope --scope manufacturing-secrets

# Add credentials
databricks secrets put-secret --scope manufacturing-secrets --key snowflake-username
databricks secrets put-secret --scope manufacturing-secrets --key snowflake-password
```

#### Step 1.3: Snowflake Setup
```bash
# Connect to Snowflake
snowsql -a your-account.snowflakecomputing.com -u your-username

# Run setup script
snowsql -f 02-infrastructure/snowflake/database-setup.sql
```

**Validation Commands:**
```bash
# Test AWS connectivity
aws s3 ls s3://manufacturing-data-pipeline-dev-us-east-1/

# Test Databricks
databricks clusters list

# Test Snowflake
snowsql -q "SELECT CURRENT_WAREHOUSE(), CURRENT_DATABASE();"
```

### Phase 2: Data Pipeline Development (Estimated: 6-8 hours)

#### Step 2.1: Upload Sample Data
```bash
# Generate sample data
cd 08-sample-data
python data_generator.py

# Upload to S3
aws s3 sync ./sample_data/ s3://manufacturing-data-pipeline-dev-us-east-1/raw/
```

#### Step 2.2: Deploy Ingestion Framework
```bash
# Upload notebooks to Databricks
databricks workspace import_dir 03-data-ingestion/ /Shared/manufacturing-pipeline/ingestion/

# Upload processing notebooks
databricks workspace import_dir 04-data-processing/ /Shared/manufacturing-pipeline/processing/

# Upload loading scripts
databricks workspace import_dir 05-data-loading/ /Shared/manufacturing-pipeline/loading/
```

#### Step 2.3: Configure Auto Loader
```bash
# Create ingestion job
databricks jobs create --json-file 06-orchestration/jobs/ingestion-job.json

# Start the ingestion stream
databricks jobs run-now --job-id <job-id>
```

**Validation Commands:**
```bash
# Check if data is being ingested
databricks workspace export /Shared/manufacturing-pipeline/validation/check-ingestion.py
python check-ingestion.py

# Verify data in Snowflake
snowsql -q "SELECT COUNT(*) FROM MANUFACTURING_DW.RAW.SENSOR_DATA_RAW;"
```

### Phase 3: Orchestration & Monitoring (Estimated: 4-6 hours)

#### Step 3.1: Set Up Databricks Jobs
```bash
# Create all pipeline jobs
for job_file in 06-orchestration/jobs/*.json; do
  databricks jobs create --json-file "$job_file"
done

# List created jobs
databricks jobs list
```

#### Step 3.2: Configure Monitoring
```bash
# Set up CloudWatch dashboards
aws cloudformation create-stack \
  --stack-name ${PROJECT_NAME}-monitoring \
  --template-body file://07-monitoring/cloudwatch/dashboard.yaml

# Configure alerts
aws cloudformation create-stack \
  --stack-name ${PROJECT_NAME}-alerts \
  --template-body file://07-monitoring/cloudwatch/alerts.yaml
```

#### Step 3.3: Set Up Data Quality Monitoring
```bash
# Install Great Expectations
pip install great-expectations==0.17.23

# Initialize data quality suite
great_expectations init

# Configure data quality checks
great_expectations checkpoint run manufacturing_data_quality
```

**Validation Commands:**
```bash
# Check job status
databricks jobs list

# View monitoring dashboards
aws cloudwatch describe-dashboards

# Test data quality
great_expectations checkpoint run manufacturing_data_quality
```

### Phase 4: Analytics & Visualization (Estimated: 3-4 hours)

#### Step 4.1: Set Up BI Connections
```bash
# Configure Snowflake connector for PowerBI/Tableau
# Download and install Snowflake ODBC driver
# Configure connection string
```

#### Step 4.2: Deploy Sample Dashboards
```bash
# Import dashboard templates
# Configure data sources
# Test dashboard functionality
```

#### Step 4.3: Set Up ML Pipeline
```bash
# Upload ML notebooks
databricks workspace import_dir 04-data-processing/ml-models/ /Shared/manufacturing-pipeline/ml/

# Register ML models
python 04-data-processing/ml-models/register-models.py
```

## 🔄 Automated Deployment Script

For streamlined deployment, use the master deployment script:

```bash
#!/bin/bash
# deploy-all.sh - Master deployment script

set -e

echo "🚀 Starting Manufacturing Data Pipeline Deployment"

# Load configuration
source ./10-deployment/config/deployment.conf

# Phase 1: Infrastructure
echo "📡 Phase 1: Setting up infrastructure..."
./10-deployment/scripts/setup-aws.sh
./10-deployment/scripts/setup-databricks.sh
./10-deployment/scripts/setup-snowflake.sh

# Phase 2: Data Pipeline
echo "🔄 Phase 2: Deploying data pipeline..."
./10-deployment/scripts/deploy-ingestion.sh
./10-deployment/scripts/deploy-processing.sh
./10-deployment/scripts/deploy-loading.sh

# Phase 3: Orchestration
echo "🎵 Phase 3: Setting up orchestration..."
./10-deployment/scripts/deploy-jobs.sh
./10-deployment/scripts/setup-monitoring.sh

# Phase 4: Validation
echo "✅ Phase 4: Running validation tests..."
./10-deployment/scripts/run-tests.sh

echo "🎉 Deployment completed successfully!"
echo "📊 Access your dashboards at: [URL]"
echo "📝 Check the logs at: ./logs/deployment.log"
```

## 📊 Post-Deployment Validation

### Data Flow Validation
```bash
# Test end-to-end data flow
python 10-deployment/validation/test-data-flow.py

# Check data quality
python 10-deployment/validation/test-data-quality.py

# Validate transformations
python 10-deployment/validation/test-transformations.py
```

### Performance Testing
```bash
# Load test the pipeline
python 10-deployment/performance/load-test.py

# Monitor resource utilization
python 10-deployment/performance/monitor-resources.py
```

### Security Validation
```bash
# Security scan
python 10-deployment/security/security-scan.py

# Access control test
python 10-deployment/security/test-permissions.py
```

## 🔧 Configuration Management

### Environment-Specific Configurations

#### Development Environment
```yaml
# config/dev.yaml
environment: dev
aws:
  region: us-east-1
  bucket_prefix: manufacturing-data-pipeline-dev
databricks:
  workspace_url: https://dev-workspace.cloud.databricks.com
  cluster_size: small
snowflake:
  warehouse: COMPUTE_WH
  database: MANUFACTURING_DW_DEV
```

#### Production Environment
```yaml
# config/prod.yaml
environment: prod
aws:
  region: us-east-1
  bucket_prefix: manufacturing-data-pipeline-prod
databricks:
  workspace_url: https://prod-workspace.cloud.databricks.com
  cluster_size: large
snowflake:
  warehouse: COMPUTE_WH_PROD
  database: MANUFACTURING_DW_PROD
```

## 🚨 Troubleshooting Guide

### Common Deployment Issues

#### AWS Issues
- **IAM Permission Denied**: Check IAM roles and policies
- **S3 Access Denied**: Verify bucket policies and cross-account access
- **Service Limits**: Request limit increases for EC2, S3

#### Databricks Issues
- **Cluster Start Failure**: Check instance availability and limits
- **Library Installation Fails**: Verify internet connectivity
- **Workspace Access Denied**: Check user permissions

#### Snowflake Issues
- **Connection Timeout**: Check network settings and firewalls
- **Warehouse Suspended**: Resume warehouse or check auto-suspend settings
- **Insufficient Privileges**: Verify user roles and grants

### Debug Commands
```bash
# Check AWS configuration
aws sts get-caller-identity
aws s3 ls

# Check Databricks connectivity
databricks workspace list

# Check Snowflake connectivity
snowsql -q "SELECT CURRENT_VERSION();"
```

## 📈 Scaling Considerations

### Horizontal Scaling
- **Databricks**: Configure auto-scaling clusters
- **Snowflake**: Use multi-cluster warehouses
- **AWS**: Implement auto-scaling groups

### Performance Optimization
- **Data Partitioning**: Optimize partition strategies
- **Caching**: Implement appropriate caching layers
- **Indexing**: Create optimal indexes in Snowflake

### Cost Optimization
- **Resource Scheduling**: Auto-suspend unused resources
- **Spot Instances**: Use spot instances for non-critical workloads
- **Storage Optimization**: Implement data lifecycle policies

## 📋 Go-Live Checklist

Before going live with the production system:

### Technical Validation
- [ ] All components deployed successfully
- [ ] End-to-end data flow tested
- [ ] Performance meets requirements
- [ ] Security measures in place
- [ ] Monitoring and alerting configured
- [ ] Backup and recovery tested

### Operational Readiness
- [ ] Team training completed
- [ ] Documentation updated
- [ ] Support procedures defined
- [ ] Escalation matrix established
- [ ] Change management process defined

### Business Validation
- [ ] Business users trained
- [ ] Dashboards and reports validated
- [ ] Data accuracy verified
- [ ] Performance expectations met
- [ ] Compliance requirements satisfied

## 🎉 Success Metrics

Track these metrics to measure deployment success:

### Technical KPIs
- **Deployment Time**: Target < 8 hours for full deployment
- **Success Rate**: >95% automated deployment success
- **Recovery Time**: <15 minutes for failed deployments

### Operational KPIs
- **Uptime**: >99.5% system availability
- **Data Freshness**: <2 hours for batch, <5 minutes for streaming
- **Performance**: <30 seconds for standard queries

### Business KPIs
- **User Adoption**: >90% of target users active
- **Time to Insight**: 10x improvement over manual processes
- **Cost Efficiency**: <$0.10 per GB processed
