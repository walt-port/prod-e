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
# Build and push backend image with default tag (latest)
./scripts/deployment/build-and-push.sh backend

# Build and push specific service with a version tag
./scripts/deployment/build-and-push.sh -t v1.0.0 backend

# Build and push Grafana or Prometheus images
./scripts/deployment/build-and-push.sh grafana
./scripts/deployment/build-and-push.sh prometheus
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

- [Infrastructure Documentation](../infrastructure/README.md)
- [Monitoring Documentation](../monitoring/README.md)
- [CI/CD Pipeline](../processes/ci-cd.md)

---

**Last Updated**: [Current Date - will be filled by system]
**Version**: 1.1
