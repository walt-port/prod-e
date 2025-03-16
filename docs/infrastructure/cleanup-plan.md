# AWS Resource Cleanup Plan

## Overview

This document outlines the cleanup plan for AWS resources in the `prod-e` project. It identifies resources that need attention, describes the issues, and provides solutions for cleanup.

## Issues Identified

Based on the resource checks, the following issues were identified:

1. **Grafana Service Issues**:

   - Multiple running tasks when only one desired
   - Tasks in UNHEALTHY state
   - Tasks using old task definitions

2. **Prometheus Service Issues**:

   - Unhealthy target in target group
   - Inaccessible metrics endpoint

3. **Lambda Function Issues**:

   - Lambda function for Grafana backup not properly connected to CloudWatch Events

4. **Security Group Issues**:
   - Multiple duplicate security groups
   - Unused security groups

## Solutions Implemented

### 1. Grafana Service Cleanup

We created a script to identify and stop unhealthy Grafana tasks:

- `scripts/fix-grafana-tasks.sh`: Identifies and stops tasks that are:
  - In UNHEALTHY state
  - Using old task definitions
  - Exceeding the desired count

Running this script with the `--force` flag successfully cleaned up the service:

- Stopped unhealthy tasks
- Force-deployed the latest version
- Verified that the service is now stable with desired count: 1, running count: 1, all HEALTHY

### 2. Prometheus Service Fixes

The Prometheus service had issues with its health check. We:

- Identified that the Prometheus target was unhealthy due to timeout on the health check
- Forced a redeployment of the service to ensure a clean start

Future improvements should include:

- Adding a health check command to the Prometheus task definition
- Modifying the `prometheus.yml` configuration with the correct scrape targets
- Ensure the Prometheus service is registered with the target group

### 3. Lambda Function Fixes

The Lambda function for Grafana backup wasn't connected to its trigger:

- Connected the CloudWatch Events rule to the Lambda function using:
  ```
  aws events put-targets --rule grafana-backup-schedule --targets "Id"="1","Arn"="arn:aws:lambda:us-west-2:043309339649:function:grafana-backup"
  ```
- The backup function should now run daily to copy Grafana data to S3

### 4. Security Group Cleanup

Multiple duplicate and unused security groups were found:

- Created `scripts/cleanup-security-groups.sh` to identify which security groups are in use
- The script checks if security groups are referenced by:
  - EC2 instances
  - Load balancers (classic and application)
  - RDS instances
  - ECS services
  - Lambda functions
  - Other security groups

The script identified the following **unused security groups** that can be safely deleted:

- `efs-mount-security-group (sg-0be700337c9fb39cf)`
- `prom-security-group (sg-0017d666e5148acac)`
- `ecs-security-group (sg-0a70331071c677329)`
- `db-security-group (sg-095f444f62444fc95)`

These should be deleted using the `./scripts/cleanup-security-groups.sh --force` command after verification.

The following security groups are actively in use and should be kept:

- `alb-security-group (sg-09bee73fe1eb42ec0)` - Referenced by other security groups
- `ecs-security-group (sg-03b80c231b15f14ec)` - Used by the `prod-e-service` ECS service
- `alb-security-group (sg-0cbf75c5632047150)` - Used by the Application Load Balancer
- `prom-security-group (sg-00f42963e977bd05b)` - Used by the `prod-e-prom-service` ECS service
- `grafana-security-group (sg-0e17e265b8fcfcaa4)` - Used by the `grafana-service` ECS service and Lambda function
- `db-security-group (sg-0413691b566e94dff)` - Used by the `postgres-instance` RDS database

## Recommended Next Steps

1. **Monitoring Improvement**:

   - Update Prometheus task definition to include a health check
   - Fix the Prometheus configuration to correctly scrape metrics
   - Create a CloudWatch dashboard for monitoring the services

2. **Infrastructure as Code Improvements**:

   - Refactor `main.ts` to separate components into individual files
   - Add a circuit breaker to the Prometheus service to handle failures gracefully
   - Fix the target group registration for Prometheus in the infrastructure code

3. **Security Group Management**:

   - Run the security group cleanup script with the `--force` flag after verifying
   - Implement tagging standards for all security groups
   - Document the purpose of each security group

4. **Automated Cleanup**:
   - Integrate the cleanup scripts into the GitHub Actions workflow
   - Schedule regular runs of the cleanup scripts
   - Add monitoring and alerting for resource usage

## Execution Timeline

| Task                                 | Status    | Date Completed | Notes                                  |
| ------------------------------------ | --------- | -------------- | -------------------------------------- |
| Fix Grafana tasks                    | Completed | 2025-03-16     | Service now stable                     |
| Connect Lambda to CloudWatch Events  | Completed | 2025-03-16     | Backup should now run daily            |
| Create security group cleanup script | Completed | 2025-03-16     | Identified 4 unused security groups    |
| Force redeploy Prometheus            | Completed | 2025-03-16     | Still needs target group configuration |

## Conclusion

The cleanup process has successfully addressed the immediate issues with the Grafana service and Lambda function configuration. Additional work is needed to fully resolve the Prometheus service issues and to clean up the 4 identified unused security groups after proper verification.

The implemented scripts provide a foundation for ongoing maintenance and can be incorporated into automated workflows to prevent similar issues in the future.
