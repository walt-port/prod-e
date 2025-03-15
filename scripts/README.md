# Scripts

This directory contains utility scripts for managing, monitoring, and maintaining the Production Experience Showcase infrastructure.

## Overview

These scripts provide automation for common DevOps tasks such as checking resource status, building and deploying container images, tearing down infrastructure, and creating Lambda function packages.

## Available Scripts

| Script                                     | Purpose                                              | Language |
| ------------------------------------------ | ---------------------------------------------------- | -------- |
| [build-and-push.sh](#build-and-push)       | Build and push Docker images to ECR                  | Bash     |
| [create-lambda-zip.js](#create-lambda-zip) | Create deployment package for Lambda functions       | Node.js  |
| [resource_check.sh](#resource-check)       | Check status of all AWS resources                    | Bash     |
| [teardown.py](#teardown)                   | Clean up all AWS resources with fine-grained control | Python   |
| [monitor-health.sh](#monitor-health)       | Monitor health of all services with alerting         | Bash     |
| [backup-database.sh](#backup-database)     | Create and manage RDS database backups               | Bash     |
| [rollback.sh](#rollback)                   | Roll back deployments to previous versions           | Bash     |
| [cleanup-resources.sh](#cleanup-resources) | Clean up unused AWS resources to reduce costs        | Bash     |

## Scripting Languages

This directory contains scripts in multiple languages (Bash, Python, and Node.js). While consistency is important, we've chosen the right language for each task based on:

1. **Task complexity**: Python for complex orchestration (teardown.py), Bash for straightforward tasks
2. **Available libraries**: Using Node.js for ZIP creation leverages the JSZip library
3. **AWS interactions**: Python with boto3 provides more sophisticated error handling and dependency management when working with AWS resources
4. **Maintenance consideration**: Each script uses the language best suited for long-term maintenance of that particular task

## Script Details

### <a name="build-and-push"></a>build-and-push.sh

Builds and pushes Docker images to Amazon ECR repositories.

**Features:**

- Automatic ECR repository creation if it doesn't exist
- AWS account detection and authentication
- Proper tagging and versioning

**Usage:**

```bash
# Basic usage (builds and pushes backend image)
./scripts/build-and-push.sh

# Build specific image (backend, prometheus, or grafana)
./scripts/build-and-push.sh --image backend
./scripts/build-and-push.sh --image prometheus
./scripts/build-and-push.sh --image grafana

# Build all images
./scripts/build-and-push.sh --all
```

**Requirements:**

- Docker installed and running
- AWS CLI configured with appropriate credentials
- Appropriate Dockerfiles present in respective directories

### <a name="create-lambda-zip"></a>create-lambda-zip.js

Creates a ZIP deployment package for AWS Lambda functions.

**Features:**

- Packages Lambda function code into a ZIP file
- Creates proper directory structure for Lambda deployment
- Works with Node.js Lambda functions

**Usage:**

```bash
# Create Lambda ZIP package
node scripts/create-lambda-zip.js
```

**Requirements:**

- Node.js installed
- JSZip package installed (`npm install jszip`)

### <a name="resource-check"></a>resource_check.sh

Provides comprehensive status checks for all AWS resources used in the project.

**Features:**

- Color-coded output for easy status identification
- Checks for VPC, subnets, security groups, route tables
- Checks RDS database instances
- Checks ECS clusters, services, and tasks
- Checks ECR repositories
- Checks Terraform state (S3 and DynamoDB)
- Checks monitoring components (Prometheus, Grafana)
- Checks Lambda functions and event rules
- Checks EFS file systems and mount targets

**Usage:**

```bash
# Check all resources
./scripts/resource_check.sh

# Check specific resource category
./scripts/resource_check.sh --vpc
./scripts/resource_check.sh --ecs
./scripts/resource_check.sh --monitoring
```

**Requirements:**

- AWS CLI configured with appropriate credentials
- `jq` installed for JSON parsing

**Notes:**

- Uses bash arithmetic for size calculations (no dependency on `bc`)
- Identifies Grafana service correctly using the service name `grafana-service`
- Properly handles EFS resources with multiple mount targets and access points

### <a name="teardown"></a>teardown.py

Safely and methodically destroys AWS resources with detailed control and visibility.

**Features:**

- Dry-run mode to preview resources that would be deleted
- Confirmation step to prevent accidental deletion
- Handles dependencies correctly by deleting in the proper order
- Detailed output during the process

**Usage:**

```bash
# Show resources that would be deleted (dry run)
python scripts/teardown.py --dry-run

# Delete resources with confirmation
python scripts/teardown.py

# Target specific region or project
python scripts/teardown.py --region us-west-2 --project-tag prod-e
```

**Requirements:**

- Python 3.6 or higher
- AWS SDK for Python (boto3): `pip install boto3`
- AWS credentials configured

### <a name="monitor-health"></a>monitor-health.sh

Monitors the health of all services and sends alerts when issues are detected.

**Features:**

- Checks ECS services, tasks, and deployments
- Checks RDS instance status
- Checks load balancers and target groups
- Monitors endpoint health via ALB with timeout detection
- Supports Slack and email alerts
- Can run continuously with a configurable interval

**Usage:**

```bash
# Run health check once
./scripts/monitor-health.sh --once

# Run continuously with alerts to Slack
./scripts/monitor-health.sh --alerts --slack https://hooks.slack.com/... --interval 300
```

**Requirements:**

- AWS CLI configured with appropriate credentials
- curl for endpoint checks
- mailx package for email notifications (if using email alerts)

**Notes:**

- Uses the ALB DNS name for endpoint checks to avoid internal DNS resolution issues
- Tests appropriate paths for each service endpoint (e.g., `/grafana/api/health` for Grafana)
- Properly handles timeouts and reports health status accurately

### <a name="backup-database"></a>backup-database.sh

Creates and manages backups of RDS database instances.

**Features:**

- Creates RDS snapshots with proper tagging
- Exports snapshots to S3 for long-term storage
- Configurable retention policy for managing old snapshots
- S3 lifecycle configuration for tiered storage cost optimization

**Usage:**

```bash
# Create backup with default settings
./scripts/backup-database.sh --db-instance prod-e-db

# Create backup with custom settings
./scripts/backup-database.sh --db-instance prod-e-db --keep 5 --bucket my-backup-bucket
```

**Requirements:**

- AWS CLI configured with appropriate credentials
- IAM role for RDS snapshot export

### <a name="rollback"></a>rollback.sh

Handles rolling back deployments in case of issues.

**Features:**

- Rolls back to previous ECS task definitions
- Can roll back to specific container image versions
- Monitors rollback deployment status
- Optionally rolls back Terraform state
- Supports rolling back individual services or all services

**Usage:**

```bash
# Roll back backend service to previous task definition
./scripts/rollback.sh backend

# Roll back to specific image tag
./scripts/rollback.sh -t v1.0.0 -r prod-e-backend backend

# Roll back all services without confirmation
./scripts/rollback.sh --auto-approve all
```

**Requirements:**

- AWS CLI configured with appropriate credentials
- jq for JSON parsing

### <a name="cleanup-resources"></a>cleanup-resources.sh

Identifies and optionally removes unused AWS resources to reduce costs.

**Features:**

- Cleans up old ECR images while keeping the latest
- Removes unattached EBS volumes
- Deletes old EBS and RDS snapshots
- Sets retention policies on CloudWatch log groups
- Removes old Lambda function versions
- Dry-run mode to preview changes

**Usage:**

```bash
# List unused resources (dry run)
./scripts/cleanup-resources.sh

# Clean up unused resources
./scripts/cleanup-resources.sh --force

# Clean up resources older than 14 days
./scripts/cleanup-resources.sh --days 14 --force
```

**Requirements:**

- AWS CLI configured with appropriate credentials
- jq for JSON parsing

## Best Practices

When using these scripts, follow these best practices:

1. **Always run in a test environment first** before using in production
2. **Review actions** before confirming destructive operations
3. **Back up important data** before making infrastructure changes
4. **Keep AWS credentials secure** and use roles with appropriate permissions
5. **Use version control** to track changes to scripts

## Contributing

When adding new scripts to this directory:

1. Use descriptive names that reflect the script's purpose
2. Add proper documentation in the script header
3. Make scripts executable with `chmod +x`
4. Update this README with information about the new script
5. Consider adding error handling and logging to ensure reliability
6. Add a section in this README following the established format
7. Choose the appropriate language for the script's functionality

## Related Documentation

- [Infrastructure Documentation](../docs/infrastructure/README.md)
- [Deployment Guide](../docs/guides/deployment-guide.md)
- [Monitoring Documentation](../docs/monitoring/README.md)
