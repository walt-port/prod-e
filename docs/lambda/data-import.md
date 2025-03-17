# Data Import Lambda Function

**Version:** 1.0
**Last Updated:** March 17, 2025
**Owner:** Backend Team

## Overview

The Data Import Lambda function provides an automated mechanism for importing data into the Production Experience Showcase database. It can be triggered by S3 events (when new data files are uploaded) or scheduled events (for regular imports).

## Architecture

The Lambda function integrates with the following AWS services:

- **S3**: Monitors buckets for new data files to import
- **RDS**: Imports data into the PostgreSQL database
- **Secrets Manager**: Retrieves database credentials securely
- **EventBridge**: Triggers scheduled imports

## Configuration

The Lambda function uses the following environment variables:

| Variable         | Description                                                  | Default                 |
| ---------------- | ------------------------------------------------------------ | ----------------------- |
| `DB_SECRET_NAME` | Name of the Secrets Manager secret containing DB credentials | `prod-e-db-credentials` |
| `S3_BUCKET`      | S3 bucket name for manual import trigger (optional)          | -                       |
| `LOG_LEVEL`      | Logging level (debug, info, warn, error)                     | `info`                  |

## Trigger Methods

### S3 Event Trigger

When a new file is uploaded to the configured S3 bucket, the Lambda function is automatically triggered. The function:

1. Downloads the file from S3
2. Parses the data (JSON format expected)
3. Imports the data into the database

### Scheduled Execution

The function can be scheduled to run periodically using EventBridge rules. This is useful for:

- Regular data imports from external systems
- Periodic data cleanup or validation

## Data Format

The function expects data in JSON format:

```json
[
  {
    "name": "metric_name",
    "value": 123.45,
    "timestamp": "2025-03-17T12:00:00Z"
  },
  {
    "name": "another_metric",
    "value": 67.89,
    "timestamp": "2025-03-17T12:05:00Z"
  }
]
```

## Deployment

The function is automatically deployed as part of the CI/CD pipeline:

1. Code is built using `npm run build`
2. Lambda deployment package is created
3. Function is deployed via CDK

## Monitoring and Logging

- CloudWatch Logs capture function execution details
- Custom metrics track import success rates and volumes
- Alarms are configured for failures and performance issues

## Security Considerations

- Database credentials are securely stored in AWS Secrets Manager
- Function has minimal IAM permissions following least privilege
- All data in transit is encrypted using HTTPS/TLS
- Database connections use SSL

## Error Handling

The function implements robust error handling:

- Database transaction rollback on error
- Retry mechanism for transient failures
- Dead-letter queue for failed imports
- Error notifications via SNS

## Related Documentation

- [Infrastructure Documentation](../infrastructure.md)
- [Resource Management](../resource-management.md)
- [Database Schema](../database/schema.md)
