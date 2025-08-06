# Infrastructure Setup Guide

## 🏗️ Infrastructure Overview

This directory contains all the configuration files and scripts needed to set up the cloud infrastructure for the data pipeline project.

## 📁 Directory Structure

```
02-infrastructure/
├── aws/                    # AWS infrastructure setup
│   ├── s3-setup.md        # S3 bucket configuration
│   ├── iam-policies.json  # IAM roles and policies
│   ├── cloudformation/    # CloudFormation templates
│   └── terraform/         # Terraform configurations
├── databricks/            # Databricks workspace setup
│   ├── cluster-config.json
│   ├── workspace-setup.md
│   └── unity-catalog/
├── snowflake/             # Snowflake setup
│   ├── database-setup.sql
│   ├── warehouse-config.sql
│   └── rbac-setup.sql
└── monitoring/            # Monitoring and alerting
    ├── cloudwatch/
    ├── datadog/
    └── custom-metrics/
```

## 🚀 Quick Start

### Prerequisites
1. **AWS CLI** installed and configured
2. **Databricks CLI** installed
3. **SnowSQL** installed
4. **Terraform** (optional, for IaC)

### Setup Order
1. **AWS Infrastructure** (S3, IAM, networking)
2. **Databricks Workspace** (clusters, catalogs)
3. **Snowflake Environment** (databases, warehouses)
4. **Connectivity** (cross-service integration)
5. **Monitoring** (alerts, dashboards)

## 🔧 Configuration Management

### Environment Variables
Create a `.env` file with the following variables:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
S3_BUCKET_PREFIX=manufacturing-data-pipeline

# Databricks Configuration
DATABRICKS_HOST=https://your-workspace.cloud.databricks.com
DATABRICKS_TOKEN=your-access-token

# Snowflake Configuration
SNOWFLAKE_ACCOUNT=your-account.snowflakecomputing.com
SNOWFLAKE_USER=your-username
SNOWFLAKE_PASSWORD=your-password
SNOWFLAKE_DATABASE=MANUFACTURING_DW
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
```

### Security Best Practices
- Store sensitive credentials in AWS Secrets Manager
- Use IAM roles instead of access keys when possible
- Enable MFA for all admin accounts
- Implement least privilege access principles

## 📊 Cost Estimation

### Development Environment
- **AWS**: $50/month
- **Databricks**: $200/month
- **Snowflake**: $150/month
- **Total**: $400/month

### Production Environment
- **AWS**: $200/month
- **Databricks**: $1,000/month
- **Snowflake**: $800/month
- **Total**: $2,000/month

## 🔍 Validation Checklist

After completing the setup, verify:

- [ ] **AWS S3**: Buckets created with proper permissions
- [ ] **IAM**: Roles configured for cross-service access
- [ ] **Databricks**: Workspace accessible and clusters running
- [ ] **Snowflake**: Database and warehouse operational
- [ ] **Connectivity**: All services can communicate
- [ ] **Security**: Encryption enabled everywhere
- [ ] **Monitoring**: Basic alerts configured

## 🆘 Troubleshooting

### Common Issues
1. **Permission Denied**: Check IAM roles and policies
2. **Network Timeout**: Verify security groups and VPC settings
3. **Authentication Failed**: Validate credentials and tokens
4. **Resource Limits**: Check service quotas and limits

### Support Resources
- AWS Documentation: https://docs.aws.amazon.com/
- Databricks Documentation: https://docs.databricks.com/
- Snowflake Documentation: https://docs.snowflake.com/

## 📞 Getting Help

If you encounter issues:
1. Check the troubleshooting section
2. Review the vendor documentation
3. Contact the development team
4. Escalate to vendor support if needed
