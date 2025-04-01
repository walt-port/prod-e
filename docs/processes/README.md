# Process Documentation

This directory contains documentation for the operational processes of the Production Experience Showcase.

## Available Documentation

### Core Processes

- [CI/CD Process](./ci-cd.md) - Continuous Integration and Deployment workflow.
- [GitHub Workflows](./github-workflows.md) - Automated GitHub Actions workflows (monitoring, checks, cleanup).
- [Resource Management Overview](./resource-management-overview.md) - Overview of resource lifecycle, tagging, compliance, and cleanup concepts.
- [Handling Existing Resources (CDKTF)](./resource-management.md) - Technical details on how CDKTF code handles existing AWS resources during deployment.
- [Monitoring Setup](../monitoring/monitoring.md) - Configuration and setup of monitoring tools (Prometheus, Grafana, CloudWatch).

### Additional Processes

- [Testing](./testing.md) - Testing strategies and practices.
- [Audits](./audits.md) - Audit procedures and compliance.
- [Cleanup Plan (Historical)](./cleanup-plan.md) - Record of a past resource cleanup effort (March 2025).

## Diagrams

The following diagrams are available to help visualize the processes:

- [GitHub Workflows Architecture](../assets/images/workflows/workflows-diagram.svg)
- [Monitoring Architecture](../assets/images/monitoring-architecture.svg)

## Document Maintenance

All process documentation should be:

1. Reviewed quarterly
2. Updated when processes change
3. Version controlled with clear update history
4. Accessible to all team members

## Last Updated

**Last Updated**: [Current Date - will be filled by system]
**Version**: 1.1
