# Operational Monitoring

This document describes the operational monitoring setup for the Production Experience project, including health checks, resource monitoring, and automated maintenance scripts.

## Health Monitoring

The project uses a comprehensive health monitoring system to ensure all components are functioning correctly.

### Health Check Script

The `monitor-health.sh` script provides real-time monitoring of all critical infrastructure components:

- **Location**: `scripts/monitor-health.sh`
- **Purpose**: Continuously monitor the health of all services and endpoints
- **Features**:
  - Monitors ECS services (prod-e-service, prod-e-prom-service, grafana-service)
  - Checks RDS database availability
  - Verifies load balancer and target group health
  - Tests API endpoints
  - Validates Grafana and Prometheus accessibility
  - Provides color-coded output for easy status identification
  - Can run continuously or as a one-time check
  - Optional SNS notifications for alerts

### Usage

```bash
# Run once and exit
./scripts/monitor-health.sh --once

# Run continuously with 2-minute intervals
./scripts/monitor-health.sh --interval=120

# Run with alert notifications enabled
./scripts/monitor-health.sh --notify
```

## Resource Monitoring

The `resource_check.sh` script provides a comprehensive assessment of all AWS resources used in the project.

### Resource Check Script

- **Location**: `scripts/resource_check.sh`
- **Purpose**: Identify potential issues with AWS resources
- **Features**:
  - Checks VPC resources (subnets, gateways, NAT)
  - Validates RDS instances and configurations
  - Inspects ECS resources (clusters, services, tasks)
  - Verifies load balancer configurations
  - Examines ECR repositories and images
  - Confirms Terraform state management
  - Checks monitoring services (Prometheus, Grafana)
  - Validates EFS resources
  - Inspects Lambda functions
  - Identifies unused security groups
  - Detects orphaned resources

### Usage

```bash
# Run a standard resource check
./scripts/resource_check.sh

# Output results to CSV
./scripts/resource_check.sh --csv

# Specify a custom CSV output file
./scripts/resource_check.sh --csv=my-results.csv
```

## Resource Cleanup

The project includes automated cleanup scripts to manage resources and control costs.

### Cleanup Scripts

1. **cleanup-resources.sh**

   - **Purpose**: Clean up old or unused AWS resources
   - **Features**:
     - Removes old ECR images
     - Deletes unattached EBS volumes
     - Cleans up old EBS snapshots
     - Removes unused CloudWatch log groups
     - Deregisters old ECS task definitions
     - Deletes unused Lambda function versions
     - Removes unused security groups

2. **cleanup-security-groups.sh**
   - **Purpose**: Specifically target unused security groups
   - **Features**:
     - Identifies security groups not in use by any resources
     - Checks references from EC2, ELB, RDS, ECS, Lambda
     - Safely removes unused groups

## Recent Improvements

Recent improvements to the operational monitoring include:

1. **Lambda Function Detection**:

   - Updated resource check script to properly detect the Grafana backup Lambda function
   - Fixed query parameters to include both 'prod-e' and 'grafana' in function names

2. **Target Group Health**:

   - Removed unhealthy Prometheus target (10.0.4.217:9090)
   - Improved target group health reporting

3. **Task Definition Cleanup**:

   - Deregistered unused prometheus-test-task definitions
   - Reduced prom-task revisions to maintain only the most recent versions

4. **Security Group Management**:
   - Removed unused ALB security group (sg-09bee73fe1eb42ec0)
   - Improved security group usage detection

## Monitoring Dashboard

The project uses Grafana dashboards to visualize the health and performance of all components. Key dashboards include:

1. **Infrastructure Overview**: High-level view of all AWS resources
2. **ECS Service Performance**: Metrics for ECS services and tasks
3. **RDS Database Metrics**: Database performance and connection statistics
4. **API Endpoint Health**: Response times and status codes for all endpoints

## Alerting

Alerts are configured for critical infrastructure components:

1. **Service Health Alerts**: Triggered when ECS services become unhealthy
2. **Database Alerts**: Triggered for RDS performance issues or connectivity problems
3. **Endpoint Alerts**: Triggered when API endpoints return non-200 status codes
4. **Resource Utilization Alerts**: Triggered for high CPU, memory, or storage usage

## Future Enhancements

Planned enhancements to the operational monitoring include:

1. **Automated Remediation**: Scripts to automatically fix common issues
2. **Enhanced Alerting**: More granular alert thresholds and notification channels
3. **Historical Metrics**: Long-term storage and analysis of performance metrics
4. **Cost Optimization**: Additional monitoring for resource cost and usage optimization
