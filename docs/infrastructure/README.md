# Infrastructure Documentation

**Version:** 1.2
**Last Updated:** [Current Date - will be filled by system]
**Owner:** DevOps Team

## Overview

This directory contains documentation related to the infrastructure components of the Production Experience Showcase project. The infrastructure is deployed on AWS using the Cloud Development Kit for Terraform (CDKTF) with multi-AZ configuration for high availability.

## Contents

- [Network Architecture](./network-architecture.md) - Documentation about VPC, subnets, and routing
- [Load Balancer Configuration](./load-balancer.md) - Documentation about ALB, target groups, and listeners
- [RDS Database](./rds-database.md) - Documentation about RDS instance, security groups, and subnet groups
- [ECS Service](./ecs-service.md) - Documentation about ECS cluster, task definition, service, and health checks
- [Container Deployment](./container-deployment.md) - Documentation for ECR, Docker builds, and container deployment
- [Remote State Management](./remote-state.md) - Documentation for S3 remote state backend and DynamoDB state locking
- [Budget Analysis](./ongoing-budget.md) - Documentation of budget analysis and cost management
- [Prometheus Fix Details](./prometheus-fix.md) - Details on troubleshooting Prometheus deployment issues

## Multi-AZ Configuration

The infrastructure is deployed across multiple availability zones for high availability:

- VPC spans multiple availability zones in the us-west-2 region
- Public and private subnets in us-west-2a and us-west-2b
- Application Load Balancer configured across multiple AZs
- RDS database with multi-AZ subnet group
- ECS services distributed across availability zones

## Related Documentation

- [Monitoring Setup](../processes/monitoring-setup.md) - Documentation related to monitoring the infrastructure
- [AWS Resource Management](../processes/resource-management.md) - Documentation of AWS resource management
- [Deployment Guide](../guides/deployment-guide.md) - Guide for deploying the infrastructure

---

**Last Updated**: [Current Date - will be filled by system]
**Version**: 1.2
