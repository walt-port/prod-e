# AWS Budget Analysis & Resource Allocation

**Version:** 1.1
**Last Updated:** March 16, 2025
**Owner:** DevOps Team

This document provides a detailed analysis of the AWS resources used in the Production Experience Showcase project, including current costs, planned additions, and optimization opportunities.

## Current Infrastructure Costs

The following table outlines the estimated monthly costs for our current AWS infrastructure based on the latest resource inventory:

| Resource                      | Details                                    | Estimated Monthly Cost |
| ----------------------------- | ------------------------------------------ | ---------------------- |
| **EC2 (ECS Fargate)**         | 4 tasks x 0.25 vCPU, 0.5GB RAM, 24/7       | ~$50                   |
| **RDS PostgreSQL**            | db.t3.micro, PostgreSQL 14.17, 20GB        | ~$15                   |
| **Application Load Balancer** | 1 ALB with 3 target groups                 | ~$16                   |
| **NAT Gateway**               | 1 NAT (nat-0dcbf60f5c68c0787) + data proc  | ~$32                   |
| **S3 (Remote State)**         | 1 bucket, ~122.4 KiB storage               | ~$0.50                 |
| **DynamoDB (State Locking)**  | 1 table (prod-e-terraform-lock), min usage | ~$0.50                 |
| **ECR**                       | 3 repositories, 36 images total            | ~$1.50                 |
| **EFS**                       | 1 filesystem, 6 MB used                    | ~$0.50                 |
| **Lambda**                    | 1 function (grafana-backup), minimal usage | ~$0.20                 |
| **CloudWatch Logs**           | Log storage for 4 containers, Lambda       | ~$3                    |
| **Data Transfer**             | Minimal external traffic                   | ~$5                    |
| **Total Current**             |                                            | **~$124.20/month**     |

## Current Resource Inventory

As of March 16, 2025, the following resources are actively running:

### Compute Resources

- **ECS Cluster**: prod-e-cluster (ACTIVE)
  - **Services**: 3 active services
    - prod-e-service: 1/1 tasks running (HEALTHY)
    - prod-e-prom-service: 1/1 tasks running (HEALTHY)
    - grafana-service: 1/1 tasks running (HEALTHY)
  - **Tasks**: 4 tasks (3 RUNNING, 1 PROVISIONING)
  - **Task Definitions**: 3 families with multiple revisions
    - prod-e-task: 0.25 vCPU, 0.5GB RAM
    - prom-task: 0.25 vCPU, 0.5GB RAM
    - grafana-task: 0.25 vCPU, 0.5GB RAM

### Database Resources

- **RDS**: postgres-instance (db.t3.micro, PostgreSQL 14.17)
- **DB Subnet Group**: Spans multiple AZs

### Storage Resources

- **S3 Bucket**: prod-e-terraform-state (~122.4 KiB used)
- **EFS**: fs-0c95781b19367259d (6 MB used)
  - Mount target in private subnet
  - Access point configured

### Container Repositories

- **ECR Repositories**: 3 total
  - prod-e-backend: 10 images
  - prod-e-prometheus: 13 images
  - prod-e-grafana: 13 images

### Network Resources

- **VPC**: vpc-0fc6af22ecf8449ff
- **Subnets**: 4 subnets (2 public, 2 private) across 2 AZs
- **NAT Gateway**: 1 active
- **Load Balancer**: 1 ALB with 3 target groups
  - ecs-target-group-v2: HEALTHY
  - grafana-tg: HEALTHY
  - prometheus-tg: HEALTHY

### Serverless Resources

- **Lambda**: grafana-backup (128MB memory, 300s timeout)

### Security Resources

- **Security Groups**: 9 groups (6 in active use, 3 default)

## Planned Optimizations

Based on our resource analysis, we can implement the following optimizations:

| Optimization                  | Details                                 | Potential Monthly Savings |
| ----------------------------- | --------------------------------------- | ------------------------- |
| **Right-size Fargate Tasks**  | Adjust CPU/memory for actual usage      | ~$10-15                   |
| **Task Consolidation**        | Combine monitoring services if feasible | ~$12                      |
| **Clean unused ECR images**   | Retain only latest 5 per repository     | ~$0.50                    |
| **CloudWatch Logs retention** | Set appropriate retention periods       | ~$1                       |
| **Total Potential Savings**   |                                         | **~$24-$28.50/month**     |

## Total Budget Projections

- **Current Monthly Cost**: ~$124.20/month
- **After Optimizations**: ~$95.70-$100.20/month
- **Potential Future State** (with frontend): ~$108-$113/month

## Cost Optimization Strategies

The following strategies can be employed to optimize costs while maintaining required performance and reliability:

### 1. Scheduled Scaling/Shutdown

- **Approach**: Schedule dev/demo resources to automatically shut down during non-business hours
- **Implementation**: Use AWS EventBridge to trigger ECS service scaling to 0 during off-hours
- **Potential Savings**: ~30-40% of Fargate costs
- **Considerations**: Ensure proper startup scripts for clean init after downtime

### 2. Fargate Spot Instances

- **Approach**: Use Fargate Spot for non-critical workloads (e.g., monitoring, reporting)
- **Implementation**: Configure ECS capacity providers to use Spot instances
- **Potential Savings**: Up to 70% of Fargate costs for eligible workloads
- **Considerations**: May experience occasional interruptions; not suitable for critical services

### 3. Reserved Instances/Commitments

- **Approach**: For longer-term projects (1+ year), consider purchasing reservations
- **Implementation**: Analyze usage patterns and commit to 1-3 year terms
- **Potential Savings**: ~40% across eligible resources
- **Considerations**: Requires upfront commitment and stability in infrastructure requirements

### 4. Right-sizing Resources

- **Approach**: Continuously monitor resource utilization and adjust allocations
- **Implementation**: Use CloudWatch metrics to identify over-provisioned resources
- **Potential Savings**: 10-20% of overall costs
- **Considerations**: Requires active monitoring and periodic adjustments

## Resource Allocation Considerations

When planning for new features or services, consider the following cost-conscious approaches:

1. **Multi-purpose Infrastructure**: Where possible, leverage existing infrastructure (e.g., ALB) for new services
2. **Service Consolidation**: Group smaller services on shared instances where appropriate
3. **Serverless First**: Consider serverless options before container-based solutions for new features
4. **Cost-Benefit Analysis**: Perform cost projection for each new feature, with clear justification

## Monitoring and Reporting

To maintain visibility into costs:

1. **AWS Cost Explorer**: Review weekly for unexpected changes
2. **Budget Alerts**: Set at 80% and 100% of projected monthly spending
3. **Tagging Strategy**: Enforce tagging for all resources to track costs by feature/service
4. **Quarterly Review**: Perform comprehensive cost optimization review quarterly

## Assumptions and Caveats

- These estimates are based on AWS US West (Oregon) region pricing
- Actual costs may vary based on usage patterns, data transfer, and AWS pricing changes
- Estimates assume moderate traffic with typical diurnal patterns
- Storage costs are estimated based on current usage patterns

---

**Last Updated**: 2025-03-16
**Version**: 1.1
