# Data Pipeline Architecture

## 🏗️ High-Level Architecture

```mermaid
graph TB
    subgraph "Data Sources"
        A[Manufacturing Sensors]
        B[Equipment Logs]
        C[Environmental Data]
        D[Quality Metrics]
    end
    
    subgraph "AWS Cloud"
        E[S3 Raw Zone]
        F[S3 Processed Zone]
        G[S3 Archive Zone]
        H[AWS Glue Catalog]
        I[IAM Roles]
    end
    
    subgraph "Databricks"
        J[Auto Loader]
        K[Delta Lake Bronze]
        L[Delta Lake Silver]
        M[Delta Lake Gold]
        N[MLflow]
        O[Spark Clusters]
    end
    
    subgraph "Snowflake"
        P[Staging Tables]
        Q[Fact Tables]
        R[Dimension Tables]
        S[Views & Aggregates]
    end
    
    subgraph "Analytics Layer"
        T[PowerBI]
        U[Tableau]
        V[Jupyter Notebooks]
        W[ML Models]
    end
    
    A --> E
    B --> E
    C --> E
    D --> E
    
    E --> J
    J --> K
    K --> L
    L --> M
    
    F --> P
    M --> P
    P --> Q
    P --> R
    Q --> S
    R --> S
    
    S --> T
    S --> U
    M --> V
    N --> W
    
    H --> J
    I --> J
    I --> P
```

## 🔄 Data Flow Architecture

```mermaid
sequenceDiagram
    participant Sensors as IoT Sensors
    participant S3 as AWS S3
    participant DB as Databricks
    participant SF as Snowflake
    participant BI as BI Tools
    
    Sensors->>S3: Stream raw data (JSON/CSV)
    S3->>DB: Auto Loader ingestion
    DB->>DB: Data quality checks
    DB->>DB: Transform & enrich
    DB->>S3: Store processed data
    DB->>SF: Load via Snowflake Connector
    SF->>SF: Create aggregations
    SF->>BI: Serve analytics
```

## 🏛️ Medallion Architecture (Bronze, Silver, Gold)

### Bronze Layer (Raw Data)
- **Purpose**: Store raw, unprocessed data
- **Format**: Delta Lake tables
- **Schema**: Flexible, schema-on-read
- **Retention**: 2+ years for compliance

```
bronze/
├── sensor_data/
│   ├── year=2024/
│   │   ├── month=01/
│   │   │   ├── day=01/
│   │   │   └── day=02/
│   │   └── month=02/
│   └── year=2025/
├── equipment_logs/
└── quality_metrics/
```

### Silver Layer (Cleaned Data)
- **Purpose**: Cleaned, validated, and deduplicated data
- **Format**: Delta Lake with enforced schema
- **Quality**: Data quality rules applied
- **Partitioning**: By date and sensor_id

```
silver/
├── cleaned_sensor_data/
├── validated_equipment_logs/
└── processed_quality_metrics/
```

### Gold Layer (Business-Ready Data)
- **Purpose**: Aggregated, enriched data for analytics
- **Format**: Optimized Delta Lake tables
- **Access**: Business users and BI tools
- **Performance**: Z-ordered and optimized

```
gold/
├── hourly_sensor_aggregates/
├── daily_equipment_summary/
├── quality_trends/
└── anomaly_detection/
```

## 🔐 Security Architecture

```mermaid
graph LR
    subgraph "Access Control"
        A[IAM Roles]
        B[Databricks RBAC]
        C[Snowflake RBAC]
    end
    
    subgraph "Data Encryption"
        D[S3 Encryption at Rest]
        E[Databricks Encryption]
        F[Snowflake Encryption]
    end
    
    subgraph "Network Security"
        G[VPC Endpoints]
        H[Private Links]
        I[Network Policies]
    end
    
    A --> B
    B --> C
    D --> E
    E --> F
    G --> H
    H --> I
```

## 📊 Monitoring & Observability

```mermaid
graph TB
    subgraph "Data Quality"
        A[Great Expectations]
        B[Data Validation]
        C[Schema Evolution]
    end
    
    subgraph "Pipeline Monitoring"
        D[Databricks Jobs]
        E[MLflow Tracking]
        F[Airflow DAGs]
    end
    
    subgraph "Performance Monitoring"
        G[Spark UI]
        H[Snowflake Query History]
        I[Resource Utilization]
    end
    
    subgraph "Alerting"
        J[CloudWatch]
        K[PagerDuty]
        L[Slack Notifications]
    end
    
    A --> D
    B --> D
    C --> D
    D --> G
    E --> H
    F --> I
    G --> J
    H --> K
    I --> L
```

## 🎯 Non-Functional Requirements

### Performance
- **Latency**: <2 hours for batch processing, <5 minutes for streaming
- **Throughput**: Handle 1TB+ daily data volume
- **Concurrency**: Support 50+ concurrent users

### Scalability
- **Horizontal scaling**: Auto-scaling clusters
- **Storage**: Unlimited S3 and Snowflake scaling
- **Compute**: On-demand resource allocation

### Reliability
- **Availability**: 99.9% uptime SLA
- **Disaster Recovery**: Multi-region backup
- **Fault Tolerance**: Automatic retry mechanisms

### Security
- **Data Encryption**: End-to-end encryption
- **Access Control**: Role-based permissions
- **Audit Logging**: Complete audit trail

## 🔧 Technology Decisions

### Why Databricks?
- Native Spark integration
- Delta Lake for ACID transactions
- MLflow for ML lifecycle
- Auto-scaling capabilities

### Why Snowflake?
- Separate compute and storage
- Auto-scaling warehouses
- Zero-copy cloning
- Built-in optimization

### Why AWS S3?
- Virtually unlimited storage
- Multiple storage classes
- Strong integration ecosystem
- Cost-effective

## 📋 Architecture Validation Checklist

- [ ] **Scalability**: Can handle 10x current data volume
- [ ] **Performance**: Meets latency requirements
- [ ] **Security**: Follows security best practices
- [ ] **Cost**: Within budget constraints
- [ ] **Maintainability**: Easy to operate and troubleshoot
- [ ] **Flexibility**: Can adapt to changing requirements
