# Infrastructure Documentation

**Version:** 1.1
**Last Updated:** March 16, 2025
**Owner:** DevOps Team

## Overview

This directory contains documentation related to the infrastructure components of the Production Experience Showcase project. The infrastructure is deployed on AWS using the Cloud Development Kit (CDK) with multi-AZ configuration for high availability.

## Contents

- [Architecture Overview](./architecture-overview.md) - High-level architectural design and component relationships
- [Network Architecture](./network-architecture.md) - Documentation about VPC, subnets, and routing
- [Load Balancer Configuration](./load-balancer.md) - Documentation about ALB, target groups, and listeners
- [RDS Database](./rds-database.md) - Documentation about RDS instance, security groups, and subnet groups
- [ECS Service](./ecs-service.md) - Documentation about ECS cluster, task definition, service, and health checks
- [Container Deployment](./container-deployment.md) - Documentation for ECR, Docker builds, and container deployment
- [Remote State Management](./remote-state.md) - Documentation for S3 remote state backend and DynamoDB state locking
- [Budget Analysis](./ongoing-budget.md) - Documentation of budget analysis and cost management
- [Resource Tagging](./resource-tagging.md) - Documentation of resource tagging strategy and implementation

## Multi-AZ Configuration

The infrastructure is deployed across multiple availability zones for high availability:

- VPC spans multiple availability zones in the us-west-2 region
- Public and private subnets in us-west-2a and us-west-2b
- Application Load Balancer configured across multiple AZs
- RDS database with multi-AZ subnet group
- ECS services distributed across availability zones

## Related Documentation

- [Infrastructure Overview](../overview.md) - Main index for infrastructure documentation
- [Monitoring Setup](../processes/monitoring-setup.md) - Documentation related to monitoring the infrastructure
- [AWS Resource Management](../processes/aws-resource-management.md) - Documentation of AWS resource management
- [Deployment Guide](../guides/deployment-guide.md) - Guide for deploying the infrastructure

---

**Last Updated**: 2025-03-16
**Version**: 1.1
