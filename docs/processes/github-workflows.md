# GitHub Workflows

**Version:** 1.0
**Last Updated:** March 16, 2025
**Owner:** DevOps Team

## Overview

This document describes the GitHub Actions workflows configured for the Production Experience Showcase. These automated workflows help maintain infrastructure health, resource compliance, and cost optimization.

![GitHub Workflows Architecture](../assets/images/workflows/workflows-diagram.svg)

## Workflows

### Deploy Workflow (deploy.yml)

The deployment workflow is responsible for deploying the application to AWS using CDK.

**Triggers:**

- Push to main branch
- Manual workflow dispatch

**Key Functions:**

- Checkout code
- Set up Node.js
- Install dependencies
- Run linting and tests
- Deploy infrastructure with CDK
- Run post-deployment checks
- Send notifications on success/failure

### Resource Check Workflow (resource-check.yml)

The resource check workflow verifies that all AWS resources are correctly provisioned and configured according to specifications.

**Triggers:**

- After successful deployment
- Manual workflow dispatch (with option to generate CSV report)

**Key Functions:**

- Verify resource existence and configuration
- Check compliance with tagging policies
- Generate resource inventory
- Check for drift from CDK templates
- Create report (optional)
- Send notifications with findings

### Health Monitoring Workflow (health-monitor.yml)

The health monitoring workflow regularly checks the health of production services.

**Triggers:**

- Scheduled (hourly)
- Manual workflow dispatch

**Key Functions:**

- Check service health endpoints
- Verify CloudWatch metrics within expected ranges
- Test critical application flows
- Validate database connections
- Send notifications only on detected issues

### Cleanup Workflow (cleanup.yml)

The cleanup workflow identifies and optionally removes unused AWS resources to control costs.

**Triggers:**

- Scheduled (weekly)
- Manual workflow dispatch

**Key Functions:**

- Identify orphaned or unused resources
- Calculate cost impact
- Generate report of resources for cleanup
- Clean up resources (optional, with approval)
- Send notifications with cleanup summary

## Related Documentation

- [CI/CD Process](ci-cd.md)
- [AWS Resource Management](aws-resource-management.md)
- [Monitoring Setup](monitoring-setup.md)

## Appendix

### Environment Variables

The workflows use the following environment variables and secrets:

- `AWS_REGION`: The AWS region where resources are deployed
- `AWS_ACCESS_KEY_ID`: AWS access key (stored as GitHub secret)
- `AWS_SECRET_ACCESS_KEY`: AWS secret key (stored as GitHub secret)
- `SLACK_WEBHOOK_URL`: Webhook URL for Slack notifications (stored as GitHub secret)
