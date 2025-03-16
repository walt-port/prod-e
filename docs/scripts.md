# Scripts Documentation

## Overview

This document provides detailed information about the utility scripts used in the Production Experience Showcase project. These scripts automate various tasks related to infrastructure management, monitoring, deployment, and maintenance.

## Table of Contents

- [Monitoring Scripts](#monitoring-scripts)
- [Deployment Scripts](#deployment-scripts)
- [Maintenance Scripts](#maintenance-scripts)
- [Backup Scripts](#backup-scripts)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)

## Monitoring Scripts

### monitor-health.sh

Located in `scripts/monitoring/monitor-health.sh`, this script performs continuous health monitoring of all services.

#### Features

- Monitors ECS services health
- Checks Prometheus and Grafana endpoints
- Verifies database connectivity
- Supports both continuous monitoring and one-time checks

#### Usage

```bash
# Run continuously with default interval (5 min)
./scripts/monitoring/monitor-health.sh

# Run a single health check
./scripts/monitoring/monitor-health.sh --once

# Specify a custom interval (in seconds)
./scripts/monitoring/monitor-health.sh --interval 60
```

### resource_check.sh

Located in `scripts/monitoring/resource_check.sh`, this script performs comprehensive checks of AWS resources.

#### Features

- Inventories all AWS resources in the account
- Identifies resource state and health issues
- Generates CSV reports for analysis
- Detects orphaned resources
- Provides cost estimates

#### Usage

```bash
# Basic resource check
./scripts/monitoring/resource_check.sh

# Generate CSV report
./scripts/monitoring/resource_check.sh --csv=resource_report.csv

# Check specific resource types
./scripts/monitoring/resource_check.sh --resources=ec2,rds,ecs
```

## Deployment Scripts

### build-and-push.sh

Located in `scripts/deployment/build-and-push.sh`, this script automates building and pushing Docker images to ECR.

#### Features

- Builds Docker images for multiple services
- Tags images with appropriate version information
- Pushes images to Amazon ECR
- Updates service definitions if requested

#### Usage

```bash
# Build and push all images
./scripts/deployment/build-and-push.sh

# Build and push specific service
./scripts/deployment/build-and-push.sh --service backend
```

### create-lambda-zip.js

Located in `scripts/deployment/create-lambda-zip.js`, this script creates deployment packages for AWS Lambda functions.

#### Features

- Bundles Lambda function code into ZIP files
- Includes dependencies correctly
- Handles different environments (dev, test, prod)
- Optimizes package size

#### Usage

```bash
# Create deployment package for all functions
node scripts/deployment/create-lambda-zip.js

# Create deployment package for specific function
node scripts/deployment/create-lambda-zip.js --function backup
```

### rollback.sh

Located in `scripts/deployment/rollback.sh`, this script provides functionality to roll back to previous deployment versions.

#### Features

- Rolls back ECS services to previous task definitions
- Supports targeted rollback of specific services
- Includes verification steps
- Provides status reporting

#### Usage

```bash
# Roll back all services to previous version
./scripts/deployment/rollback.sh

# Roll back specific service
./scripts/deployment/rollback.sh --service backend
```

## Maintenance Scripts

### cleanup-resources.sh

Located in `scripts/maintenance/cleanup-resources.sh`, this script automates the cleanup of unused AWS resources.

#### Features

- Identifies unused or idle resources
- Supports dry-run mode for safety
- Cleans up resources based on age and usage patterns
- Generates detailed reports

#### Usage

```bash
# Dry run (no changes made)
./scripts/maintenance/cleanup-resources.sh --dry-run

# Perform actual cleanup
./scripts/maintenance/cleanup-resources.sh --force

# Keep latest 5 versions, delete older resources
./scripts/maintenance/cleanup-resources.sh --force --keep=5
```

### teardown.py

Located in `scripts/maintenance/teardown.py`, this script provides a controlled way to tear down infrastructure components.

#### Features

- Removes AWS resources in the correct order
- Supports dry-run mode
- Handles dependencies between resources
- Provides detailed output and status

#### Usage

```bash
# Preview teardown (no changes made)
python scripts/maintenance/teardown.py --dry-run

# Perform complete teardown
python scripts/maintenance/teardown.py

# Teardown specific components
python scripts/maintenance/teardown.py --components ecs,alb
```

## Backup Scripts

### backup-database.sh

Located in `scripts/backup/backup-database.sh`, this script automates database backups.

#### Features

- Creates RDS snapshots
- Exports data for long-term storage
- Manages snapshot rotation
- Supports scheduled execution

#### Usage

```bash
# Perform a backup
./scripts/backup/backup-database.sh

# Specify retention period
./scripts/backup/backup-database.sh --retention 30
```

## Usage Examples

### Regular Maintenance Tasks

```bash
# Weekly maintenance routine
./scripts/monitoring/resource_check.sh --csv=weekly_report.csv
./scripts/maintenance/cleanup-resources.sh --dry-run
# Review report, then run:
./scripts/maintenance/cleanup-resources.sh --force --keep=5
```

### Deployment Workflow

```bash
# Build and deploy
./scripts/deployment/build-and-push.sh
# If issues occur:
./scripts/deployment/rollback.sh
```

## Best Practices

1. **Always use dry-run mode first** for destructive operations
2. **Schedule regular executions** of monitoring and maintenance scripts
3. **Keep execution logs** for auditing and troubleshooting
4. **Review script output thoroughly** before taking action
5. **Ensure proper AWS credentials** are configured before running scripts

## Related Documentation

- [Infrastructure Documentation](infrastructure/README.md)
- [Monitoring Documentation](monitoring/README.md)
- [CI/CD Pipeline](processes/ci-cd.md)

---

**Last Updated**: 2025-03-16
**Version**: 1.0
