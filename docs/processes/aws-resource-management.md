# AWS Resource Management

**Version:** 1.0
**Last Updated:** March 16, 2025
**Owner:** DevOps Team

## Overview

This document outlines the processes and best practices for managing AWS resources in the Production Experience Showcase. It covers resource provisioning, monitoring, compliance, and cleanup procedures.

## Resource Provisioning

All AWS resources are provisioned using Infrastructure as Code (IaC) through AWS Cloud Development Kit (CDK). This approach ensures:

- Consistent and repeatable deployments
- Version-controlled infrastructure
- Automated resource creation and updates
- Reduced manual configuration errors

### CDK Stacks

The project uses the following CDK stacks:

| Stack Name        | Purpose                   | Key Resources                           |
| ----------------- | ------------------------- | --------------------------------------- |
| prod-e-api        | API services              | API Gateway, Lambda functions, DynamoDB |
| prod-e-monitoring | Monitoring infrastructure | Prometheus, CloudWatch alarms           |
| prod-e-network    | Network configuration     | VPC, subnets, security groups           |

## Resource Tagging

All AWS resources must follow the tagging strategy below:

| Tag Key     | Description            | Example       |
| ----------- | ---------------------- | ------------- |
| Project     | Project identifier     | `prod-e`      |
| Environment | Deployment environment | `production`  |
| Owner       | Team responsible       | `devops`      |
| CostCenter  | Billing allocation     | `engineering` |
| ManagedBy   | Management method      | `cdk`         |

## Resource Monitoring

Resources are monitored through:

1. **CloudWatch Metrics**: Performance and utilization metrics
2. **CloudWatch Alarms**: Threshold-based alerts
3. **Prometheus**: Custom application metrics
4. **Health Monitoring Workflow**: Hourly service health checks

## Resource Compliance

The Resource Check workflow (`resource-check.yml`) verifies that all resources:

1. Exist and are properly configured
2. Have the required tags
3. Follow security best practices
4. Adhere to cost optimization guidelines

### Compliance Reports

The Resource Check workflow generates reports that include:

- Resource inventory
- Compliance status
- Remediation recommendations
- Cost optimization opportunities

## Resource Cleanup

Unused or orphaned resources are identified and cleaned up through:

1. **Automated Detection**: The Cleanup workflow (`cleanup.yml`) runs weekly to identify:

   - Unused EBS volumes
   - Unattached Elastic IPs
   - Outdated Lambda versions
   - Orphaned IAM roles
   - Unused CloudWatch log groups

2. **Cleanup Process**:
   - Resources are identified and reported
   - A cleanup plan is generated
   - Resources are tagged for deletion
   - After approval, resources are removed

### Cleanup Safety Measures

To prevent accidental deletion of important resources:

1. Dry-run mode is enabled by default
2. Resources with `DoNotDelete` tag are protected
3. Recently created resources (< 7 days) are excluded
4. Manual approval is required for actual deletion

## Related Workflows

The following GitHub Actions workflows support AWS resource management:

- **Resource Check Workflow**: Verifies resource compliance after deployments
- **Cleanup Workflow**: Identifies and removes unused resources
- **Health Monitoring Workflow**: Checks service health hourly

For detailed information about these workflows, see the [GitHub Workflows](github-workflows.md) documentation.

![GitHub Workflows Architecture](../assets/images/workflows/workflows-diagram.svg)

## Related Documentation

- [CI/CD Process](ci-cd.md)
- [GitHub Workflows](github-workflows.md)
- [Monitoring Setup](monitoring-setup.md)
