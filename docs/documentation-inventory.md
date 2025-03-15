# Documentation Inventory

## Overview

This document catalogs all documentation in the Production Experience Showcase (prod-e) project, mapping relationships between documents and identifying potential gaps or redundancies.

## Root Documentation

| Document                  | Purpose                                | Related Documents       |
| ------------------------- | -------------------------------------- | ----------------------- |
| [README.md](../README.md) | Main project overview and introduction | All documentation files |

## Infrastructure Documentation

| Document                                             | Purpose                                              | Related Documents                                    |
| ---------------------------------------------------- | ---------------------------------------------------- | ---------------------------------------------------- |
| [overview.md](./overview.md)                         | Main index for infrastructure documentation          | All infrastructure docs                              |
| [network-architecture.md](./network-architecture.md) | VPC, subnets, NAT Gateway, and routing               | [multi-az-strategy.md](./multi-az-strategy.md)       |
| [load-balancer.md](./load-balancer.md)               | ALB, target groups, and listeners                    | [ecs-service.md](./ecs-service.md)                   |
| [rds-database.md](./rds-database.md)                 | RDS instance, security groups, and subnet groups     | [network-architecture.md](./network-architecture.md) |
| [ecs-service.md](./ecs-service.md)                   | ECS cluster, task definition, service, health checks | [container-deployment.md](./container-deployment.md) |
| [multi-az-strategy.md](./multi-az-strategy.md)       | Multi-AZ implementation and future plans             | [network-architecture.md](./network-architecture.md) |
| [container-deployment.md](./container-deployment.md) | ECR, Docker builds, and container deployment         | [ci-cd.md](./ci-cd.md)                               |
| [remote_state.md](./remote_state.md)                 | S3 remote state backend and DynamoDB state locking   | [overview.md](./overview.md)                         |
| [ongoing_budget.md](./ongoing_budget.md)             | Budget analysis and cost management                  | -                                                    |

## Monitoring Documentation

| Document                         | Purpose                                       | Related Documents                |
| -------------------------------- | --------------------------------------------- | -------------------------------- |
| [monitoring.md](./monitoring.md) | Prometheus and Grafana implementation         | [grafana.md](./grafana.md)       |
| [grafana.md](./grafana.md)       | Grafana-specific configuration and dashboards | [monitoring.md](./monitoring.md) |

## Process Documentation

| Document                   | Purpose                                     | Related Documents                                    |
| -------------------------- | ------------------------------------------- | ---------------------------------------------------- |
| [ci-cd.md](./ci-cd.md)     | GitHub Actions CI/CD implementation         | [container-deployment.md](./container-deployment.md) |
| [testing.md](./testing.md) | Testing approach, coverage, and examples    | [ci-cd.md](./ci-cd.md)                               |
| [audits.md](./audits.md)   | Infrastructure and codebase audit processes | [../audits/overview.md](../audits/overview.md)       |

## Audit Documentation

| Document                                                                                                     | Purpose                                 | Related Documents                                                                                            |
| ------------------------------------------------------------------------------------------------------------ | --------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| [../audits/README.md](../audits/README.md)                                                                   | Audit directory overview                | [../audits/overview.md](../audits/overview.md)                                                               |
| [../audits/overview.md](../audits/overview.md)                                                               | Main index for all audit documentation  | [../audits/README.md](../audits/README.md), [./audits.md](./audits.md)                                       |
| [../audits/codebase/README.md](../audits/codebase/README.md)                                                 | Codebase audit reports index            | [../audits/templates/codebase-audit-template.md](../audits/templates/codebase-audit-template.md)             |
| [../audits/infrastructure/README.md](../audits/infrastructure/README.md)                                     | Infrastructure audit reports index      | [../audits/templates/infrastructure-audit-template.md](../audits/templates/infrastructure-audit-template.md) |
| [../audits/security/README.md](../audits/security/README.md)                                                 | Security audit reports index            | [../audits/templates/security-audit-template.md](../audits/templates/security-audit-template.md)             |
| [../audits/templates/audit-checklist.md](../audits/templates/audit-checklist.md)                             | General checklist for audit preparation | All audit templates                                                                                          |
| [../audits/templates/codebase-audit-template.md](../audits/templates/codebase-audit-template.md)             | Template for codebase audits            | [../audits/codebase/README.md](../audits/codebase/README.md)                                                 |
| [../audits/templates/infrastructure-audit-template.md](../audits/templates/infrastructure-audit-template.md) | Template for infrastructure audits      | [../audits/infrastructure/README.md](../audits/infrastructure/README.md)                                     |
| [../audits/templates/security-audit-template.md](../audits/templates/security-audit-template.md)             | Template for security audits            | [../audits/security/README.md](../audits/security/README.md)                                                 |

## Script Documentation

| Document                                                     | Purpose                                | Related Documents                            |
| ------------------------------------------------------------ | -------------------------------------- | -------------------------------------------- |
| [../scripts/README.md](../scripts/README.md)                 | Scripts directory overview             | -                                            |
| [../scripts/RESOURCE_CHECK.md](../scripts/RESOURCE_CHECK.md) | Resource checking script documentation | [../scripts/README.md](../scripts/README.md) |

## Documentation Gaps

Based on the inventory, the following documentation gaps have been identified:

1. **Deployment Guide**: A comprehensive guide for deploying the entire system is missing
2. **Troubleshooting Guide**: Documentation for common issues and resolution steps is needed
3. **Architecture Diagrams**: Visual representations of the system architecture would be valuable
4. **User Guide**: End-user documentation for the dashboard and monitoring system
5. **Local Development Setup**: Guide for setting up a local development environment

## Redundancies

The following redundancies have been identified:

1. Implementation progress information appears in both README.md and overview.md
2. Audit process information appears in both audits/README.md and audits/overview.md
3. Deployment instructions appear partially in both README.md and overview.md

## Next Steps

1. Address identified documentation gaps
2. Resolve redundancies by consolidating information
3. Standardize documentation formats and styles
4. Implement consistent cross-referencing between documents
