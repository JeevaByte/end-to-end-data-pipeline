# AWS S3 Setup Guide

## 🪣 S3 Bucket Configuration

### Bucket Structure
Create the following S3 buckets with appropriate naming conventions:

```
manufacturing-data-pipeline-{env}-{region}
├── raw/                    # Bronze layer - raw sensor data
│   ├── sensor-data/
│   │   ├── year=2024/
│   │   │   ├── month=01/
│   │   │   └── month=02/
│   │   └── year=2025/
│   ├── equipment-logs/
│   └── quality-metrics/
├── processed/              # Silver/Gold layer - processed data
│   ├── silver/
│   │   ├── cleaned-sensors/
│   │   └── validated-equipment/
│   └── gold/
│       ├── hourly-aggregates/
│       └── daily-summaries/
├── archive/                # Long-term storage
│   ├── raw-archive/
│   └── processed-archive/
└── temp/                   # Temporary processing files
    ├── staging/
    └── checkpoints/
```

## 🔧 Manual Setup Steps

### Step 1: Create S3 Buckets

```bash
# Set environment variables
export AWS_REGION=us-east-1
export ENVIRONMENT=dev  # or prod
export BUCKET_PREFIX=manufacturing-data-pipeline

# Create main data bucket
aws s3 mb s3://${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION}

# Create archive bucket
aws s3 mb s3://${BUCKET_PREFIX}-archive-${ENVIRONMENT}-${AWS_REGION}

# Create temp bucket for processing
aws s3 mb s3://${BUCKET_PREFIX}-temp-${ENVIRONMENT}-${AWS_REGION}
```

### Step 2: Configure Bucket Policies

Apply the bucket policy to allow Databricks access:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DatabricksAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::DATABRICKS-ACCOUNT-ID:role/databricks-cross-account-role"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::manufacturing-data-pipeline-dev-us-east-1",
                "arn:aws:s3:::manufacturing-data-pipeline-dev-us-east-1/*"
            ]
        }
    ]
}
```

### Step 3: Enable Versioning and Encryption

```bash
# Enable versioning
aws s3api put-bucket-versioning \
    --bucket ${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION} \
    --versioning-configuration Status=Enabled

# Enable default encryption
aws s3api put-bucket-encryption \
    --bucket ${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION} \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'
```

### Step 4: Configure Lifecycle Policies

```json
{
    "Rules": [
        {
            "ID": "RawDataTransition",
            "Status": "Enabled",
            "Filter": {
                "Prefix": "raw/"
            },
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                },
                {
                    "Days": 365,
                    "StorageClass": "DEEP_ARCHIVE"
                }
            ]
        },
        {
            "ID": "TempDataCleanup",
            "Status": "Enabled",
            "Filter": {
                "Prefix": "temp/"
            },
            "Expiration": {
                "Days": 7
            }
        }
    ]
}
```

### Step 5: Set Up Event Notifications

Configure S3 to notify when new files arrive:

```bash
# Create SNS topic for notifications
aws sns create-topic --name manufacturing-data-pipeline-notifications

# Configure bucket notification
aws s3api put-bucket-notification-configuration \
    --bucket ${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION} \
    --notification-configuration '{
        "TopicConfigurations": [
            {
                "Id": "NewDataNotification",
                "TopicArn": "arn:aws:sns:us-east-1:123456789012:manufacturing-data-pipeline-notifications",
                "Events": [
                    "s3:ObjectCreated:*"
                ],
                "Filter": {
                    "Key": {
                        "FilterRules": [
                            {
                                "Name": "prefix",
                                "Value": "raw/"
                            }
                        ]
                    }
                }
            }
        ]
    }'
```

## 📊 Monitoring and Metrics

### CloudWatch Metrics
Enable the following metrics for monitoring:
- BucketSizeBytes
- NumberOfObjects
- RequestMetrics

### Custom Metrics
Set up custom metrics for:
- Data ingestion rate
- File processing latency
- Error rates

## 🔒 Security Configuration

### CORS Configuration (if needed for web access)
```json
{
    "CORSRules": [
        {
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET", "PUT", "POST"],
            "AllowedOrigins": ["https://your-databricks-workspace.cloud.databricks.com"],
            "ExposeHeaders": ["ETag"],
            "MaxAgeSeconds": 3000
        }
    ]
}
```

### Access Logging
```bash
# Create logging bucket
aws s3 mb s3://${BUCKET_PREFIX}-logs-${ENVIRONMENT}-${AWS_REGION}

# Enable access logging
aws s3api put-bucket-logging \
    --bucket ${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION} \
    --bucket-logging-status '{
        "LoggingEnabled": {
            "TargetBucket": "'${BUCKET_PREFIX}'-logs-'${ENVIRONMENT}'-'${AWS_REGION}'",
            "TargetPrefix": "access-logs/"
        }
    }'
```

## 🧪 Testing the Setup

### Upload Test Files
```bash
# Create a test file
echo "sensor_id,timestamp,temperature,humidity" > test-sensor-data.csv
echo "sensor_001,2024-01-01T10:00:00Z,25.5,60.2" >> test-sensor-data.csv

# Upload to S3
aws s3 cp test-sensor-data.csv s3://${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION}/raw/sensor-data/year=2024/month=01/day=01/

# Verify upload
aws s3 ls s3://${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION}/raw/sensor-data/year=2024/month=01/day=01/
```

### Verify Permissions
```bash
# Test read access
aws s3 cp s3://${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION}/raw/sensor-data/year=2024/month=01/day=01/test-sensor-data.csv ./downloaded-test.csv

# Test write access
echo "test write" > write-test.txt
aws s3 cp write-test.txt s3://${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION}/temp/
```

## 📋 Validation Checklist

After setup, verify:
- [ ] All buckets created successfully
- [ ] Bucket policies applied correctly
- [ ] Versioning enabled
- [ ] Encryption configured
- [ ] Lifecycle policies active
- [ ] Event notifications working
- [ ] Access logging enabled
- [ ] Test files uploaded successfully
- [ ] Permissions working as expected

## 🔧 Automation Script

Use this script to automate the entire S3 setup:

```bash
#!/bin/bash
# s3-setup.sh

set -e

# Configuration
export AWS_REGION=${AWS_REGION:-us-east-1}
export ENVIRONMENT=${ENVIRONMENT:-dev}
export BUCKET_PREFIX=manufacturing-data-pipeline

# Create buckets
echo "Creating S3 buckets..."
aws s3 mb s3://${BUCKET_PREFIX}-${ENVIRONMENT}-${AWS_REGION}
aws s3 mb s3://${BUCKET_PREFIX}-archive-${ENVIRONMENT}-${AWS_REGION}
aws s3 mb s3://${BUCKET_PREFIX}-temp-${ENVIRONMENT}-${AWS_REGION}
aws s3 mb s3://${BUCKET_PREFIX}-logs-${ENVIRONMENT}-${AWS_REGION}

# Apply configurations
echo "Applying bucket configurations..."
# Add your configuration commands here

echo "S3 setup completed successfully!"
```

## 🆘 Troubleshooting

### Common Issues

1. **Access Denied**
   - Check IAM permissions
   - Verify bucket policies
   - Ensure correct AWS credentials

2. **Bucket Already Exists**
   - Bucket names must be globally unique
   - Add random suffix or use different naming convention

3. **Lifecycle Policy Errors**
   - Validate JSON syntax
   - Check IAM permissions for lifecycle management

4. **Notification Configuration Fails**
   - Verify SNS topic exists
   - Check SNS topic policy allows S3 to publish
