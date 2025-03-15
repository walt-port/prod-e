# Infrastructure Documentation

## Overview

This directory contains documentation related to the infrastructure components of the Production Experience Showcase project. It includes details about network architecture, compute services, storage, and infrastructure management.

## Contents

- [Network Architecture](./network-architecture.md) - Documentation about VPC, subnets, NAT Gateway, and routing
- [Load Balancer Configuration](./load-balancer.md) - Documentation about ALB, target groups, and listeners
- [RDS Database](./rds-database.md) - Documentation about RDS instance, security groups, and subnet groups
- [ECS Service](./ecs-service.md) - Documentation about ECS cluster, task definition, service, and health checks
- [Multi-AZ Strategy](./multi-az-strategy.md) - Documentation of current multi-AZ implementation and future plans
- [Container Deployment](./container-deployment.md) - Documentation for ECR, Docker builds, and container deployment
- [Remote State Management](./remote-state.md) - Documentation for S3 remote state backend and DynamoDB state locking
- [Budget Analysis](./ongoing-budget.md) - Documentation of budget analysis and cost management

## Related Documentation

- [Infrastructure Overview](../overview.md) - Main index for infrastructure documentation
- [Monitoring Documentation](../monitoring/) - Documentation related to monitoring the infrastructure
- [Deployment Guide](../guides/deployment-guide.md) - Guide for deploying the infrastructure

---

**Last Updated**: 2025-03-15
**Version**: 1.0
