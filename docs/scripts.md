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

**Purpose**: Performs a comprehensive check of all AWS resources in the prod-e project.

**Location**: `scripts/resource_check.sh`

**Usage**:

```bash
./scripts/resource_check.sh
```

**Description**:
This script provides a detailed assessment of the health and configuration of all AWS resources used in the prod-e project including:

1. VPC resources (subnets, internet gateways, NAT gateways)
2. RDS instances and database configurations
3. ECS resources (clusters, services, tasks, task definitions)
4. Load balancer configurations and target health
5. ECR repositories and image information
6. Terraform state management
7. Monitoring services (Prometheus, Grafana)
8. EFS resources
9. Lambda functions (including grafana-backup)
10. Security groups
11. Orphaned or unused resources

The script outputs a comprehensive report with color-coded status indicators for easy identification of issues.

### monitor-health.sh

**Purpose**: Monitors the health of critical services and endpoints.

**Location**: `scripts/monitor-health.sh`

**Usage**:

```bash
./scripts/monitor-health.sh [OPTIONS]
```

**Options**:

- `--once`: Run the health check once and exit (default is continuous monitoring)
- `--notify`: Enable SNS notifications for alerts
- `--interval=SECONDS`: Set the check interval in seconds (default: 60)
- `--region=REGION`: Specify the AWS region (default: us-west-2)
- `--help`: Display help message

**Description**:
This script monitors the health of critical infrastructure components including:

1. ECS services (prod-e-service, prod-e-prom-service, grafana-service)
2. RDS database instances
3. Load balancer and target groups
4. API endpoints
5. Grafana and Prometheus services

By default, it runs continuously at specified intervals. Use the `--once` flag to run a single check.

### cleanup-resources.sh

**Purpose**: Cleans up unused or old AWS resources to optimize costs.

**Location**: `scripts/cleanup-resources.sh`

**Usage**:

```bash
./scripts/cleanup-resources.sh [OPTIONS]
```

**Options**:

- `--force`: Actually delete resources (default is dry run)
- `--age=DAYS`: Age threshold in days for resource deletion (default: 7)
- `--keep=COUNT`: Number of latest versions to keep (default: 5)
- `--region=REGION`: Specify the AWS region (default: us-west-2)
- `--help`: Display help message

**Description**:
This script identifies and optionally deletes:

1. Old ECR images while keeping the latest N versions
2. Unattached EBS volumes
3. Old EBS snapshots
4. Unused CloudWatch log groups
5. Old ECS task definitions
6. Unused Lambda function versions
7. Unused security groups

By default, it runs in dry-run mode, showing what would be deleted without making changes.

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
