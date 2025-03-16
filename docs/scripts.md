# Scripts Documentation

## Overview

This document provides details about the various scripts used for AWS resource management, monitoring, and cleanup in the prod-e project.

## Maintenance Scripts

### fix-grafana-tasks.sh

**Purpose**: Identifies and fixes issues with Grafana service tasks in ECS.

**Location**: `scripts/fix-grafana-tasks.sh`

**Usage**:

```bash
./scripts/fix-grafana-tasks.sh [OPTIONS]
```

**Options**:

- `--force`: Actually stop unhealthy or outdated tasks (default is dry run)
- `--region=REGION`: Specify the AWS region (default: us-west-2)
- `--cluster=CLUSTER`: Specify the ECS cluster (default: prod-e-cluster)
- `--service=SERVICE`: Specify the ECS service (default: grafana-service)
- `--help`: Display help message

**Description**:
This script addresses common issues with the Grafana service in ECS by identifying and stopping:

1. Tasks that are in an UNHEALTHY state
2. Tasks that are using old task definitions
3. Excess tasks beyond the desired count

By default, it runs in dry-run mode, showing what would be done without making changes. Use the `--force` flag to actually stop the identified tasks.

### cleanup-security-groups.sh

**Purpose**: Identifies unused security groups that can be safely deleted.

**Location**: `scripts/cleanup-security-groups.sh`

**Usage**:

```bash
./scripts/cleanup-security-groups.sh [OPTIONS]
```

**Options**:

- `--force`: Actually delete unused security groups (default is dry run)
- `--region=REGION`: Specify the AWS region (default: us-west-2)
- `--project=TAG`: Project tag to filter security groups (default: prod-e)
- `--help`: Display help message

**Description**:
This script analyzes security groups in your AWS account to identify those that are not in use by any resources. It checks for references from:

- EC2 instances
- Load balancers (classic and application)
- RDS instances
- ECS services
- Lambda functions
- Other security groups (inbound rules)

By default, it runs in dry-run mode, showing what would be deleted without making changes. Use the `--force` flag to actually delete the unused security groups after verification.

### resource_check.sh

**Purpose**: Comprehensive check of AWS resources to identify potential issues.

**Location**: `scripts/resource_check.sh`

**Usage**:

```bash
./scripts/resource_check.sh [OPTIONS]
```

**Options**:

- `--csv`: Output results to a CSV file (default: resource_check_results.csv)
- `--csv=FILE`: Output results to the specified CSV file
- `--help`: Display help message

**Description**:
This script performs a comprehensive check of various AWS resources in the prod-e project, including:

- VPC resources (subnets, gateways, Elastic IPs)
- RDS instances and snapshots
- ECS resources (clusters, services, tasks)
- Load balancer health
- ECR repositories
- Terraform state
- Monitoring services (Prometheus, Grafana)
- EFS resources
- Lambda functions
- Security groups
- Orphaned resources (unattached EBS volumes, inactive resources)

The script highlights issues with color-coded output and can optionally generate a CSV report.

### cleanup-resources.sh

**Purpose**: Cleans up unused AWS resources to reduce costs.

**Location**: `scripts/cleanup-resources.sh`

**Usage**:

```bash
./scripts/cleanup-resources.sh [OPTIONS]
```

**Options**:

- `--dry-run`: Run in dry-run mode without making changes (default)
- `--force`: Actually delete resources
- `--keep=N`: Keep N latest versions of resources (default: 5)
- `--region=REGION`: Specify the AWS region (default: us-west-2)
- `--help`: Display help message

**Description**:
This script identifies and cleans up various unused AWS resources to reduce costs, including:

- Untagged or unused EC2 instances
- Unattached EBS volumes
- Old EBS snapshots
- Unused Elastic IPs
- Old ECR images
- Old CloudWatch log groups
- Inactive Lambda function versions
- Unused security groups

By default, it runs in dry-run mode. Use the `--force` flag to actually delete the identified resources.

## Backup Scripts

### backup-database.sh

**Purpose**: Creates and manages backups of the RDS database.

**Location**: `scripts/backup-database.sh`

**Usage**:

```bash
./scripts/backup-database.sh [OPTIONS]
```

**Options**:

- `--instance=NAME`: Database instance identifier (default: postgres-instance)
- `--keep=N`: Number of snapshots to keep (default: 7)
- `--bucket=NAME`: S3 bucket for exports (default: prod-e-db-backups)
- `--region=REGION`: AWS region (default: us-west-2)
- `--help`: Display help message

**Description**:
This script creates RDS snapshots and exports them to S3. It manages the lifecycle of snapshots, keeping only the specified number of most recent ones and deleting older snapshots to save storage costs.

## CI/CD Scripts

### deploy.sh

**Purpose**: Manages deployments of the application.

**Location**: `scripts/deploy.sh`

**Usage**:

```bash
./scripts/deploy.sh [OPTIONS]
```

**Options**:

- `--environment=ENV`: Target environment (dev, staging, prod)
- `--help`: Display help message

**Description**:
This script orchestrates the deployment process, including:

1. Building Docker images
2. Pushing to ECR
3. Updating ECS service task definitions
4. Initiating deployments
5. Verifying deployment health

## Implementation Notes

These scripts follow best practices for AWS resource management:

- Run in dry-run mode by default for safety
- Provide clear output about actions and changes
- Include proper error handling
- Use AWS CLI with appropriate permissions

## Related Documentation

- [Infrastructure Documentation](./infrastructure/README.md)
- [AWS Resource Cleanup Plan](./infrastructure/cleanup-plan.md)
- [ECS Service Documentation](./infrastructure/ecs-service.md)
- [Monitoring Documentation](./monitoring/README.md)
