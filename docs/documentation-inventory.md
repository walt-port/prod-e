# Documentation Inventory

## Overview

This document catalogs all documentation in the Production Experience Showcase (prod-e) project, mapping relationships between documents and identifying potential gaps or redundancies.

## Table of Contents

- [Root Documentation](#root-documentation)
- [Infrastructure Documentation](#infrastructure-documentation)
- [Monitoring Documentation](#monitoring-documentation)
- [Process Documentation](#process-documentation)
- [User Guides](#user-guides)
- [Audit Documentation](#audit-documentation)
- [Script Documentation](#script-documentation)
- [Documentation Standards](#documentation-standards)
- [Documentation Gaps](#documentation-gaps)
- [Next Steps](#next-steps)

## Root Documentation

| Document                                | Purpose                                     | Related Documents       |
| --------------------------------------- | ------------------------------------------- | ----------------------- |
| [README.md](../README.md)               | Main project overview and introduction      | All documentation files |
| [DOCUMENTATION.md](../DOCUMENTATION.md) | Central documentation index                 | All documentation files |
| [docs/overview.md](./overview.md)       | Main index for infrastructure documentation | All infrastructure docs |

## Infrastructure Documentation

| Document                | Path                                   | Purpose                                                                                                                                                  | Related Documents                                        |
| ----------------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| Infrastructure Overview | infrastructure/README.md               | Provides a high-level overview of the infrastructure architecture                                                                                        | network-architecture.md, ecs-service.md, rds-database.md |
| Network Architecture    | infrastructure/network-architecture.md | Details the VPC, subnets, and networking components                                                                                                      | load-balancer.md, multi-az-strategy.md                   |
| Load Balancer           | infrastructure/load-balancer.md        | Documents the Application Load Balancer configuration                                                                                                    | network-architecture.md, ecs-service.md                  |
| Multi-AZ Strategy       | infrastructure/multi-az-strategy.md    | Documents multi-AZ implementation                                                                                                                        | network-architecture.md, rds-database.md                 |
| RDS Database            | infrastructure/rds-database.md         | Details the PostgreSQL RDS instance configuration                                                                                                        | multi-az-strategy.md                                     |
| ECS Service             | infrastructure/ecs-service.md          | Explains the ECS cluster, services, and task definitions                                                                                                 | load-balancer.md                                         |
| Container Deployment    | infrastructure/container-deployment.md | Outlines the container deployment strategy, including security considerations and operational aspects.                                                   | Infrastructure Overview, CI/CD Pipeline                  |
| Remote State            | infrastructure/remote-state.md         | Explains the Terraform remote state configuration and backup strategy.                                                                                   | Infrastructure Overview, Disaster Recovery               |
| Resource Cleanup Plan   | infrastructure/cleanup-plan.md         | Details the approach for identifying and cleaning up unused AWS resources to control costs.                                                              | Cost Management, Infrastructure Overview                 |
| Ongoing Budget          | infrastructure/ongoing-budget.md       | Provides cost estimates and budget planning for ongoing infrastructure expenses.                                                                         | Cost Management, Resource Cleanup Plan                   |
| Prometheus Fix          | infrastructure/prometheus-fix.md       | Documents the issues and fixes implemented for the Prometheus monitoring system, including Grafana data source configuration and security group cleanup. | Monitoring Overview, Grafana Documentation               |

## Monitoring Documentation

| Document                                                                 | Purpose                                                  | Related Documents                                                                                              |
| ------------------------------------------------------------------------ | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| [monitoring/monitoring.md](./monitoring/monitoring.md)                   | Prometheus and Grafana implementation                    | [monitoring/grafana.md](./monitoring/grafana.md), [monitoring/prometheus.md](./monitoring/prometheus.md)       |
| [monitoring/grafana.md](./monitoring/grafana.md)                         | Grafana-specific configuration and dashboards            | [monitoring/monitoring.md](./monitoring/monitoring.md), [monitoring/prometheus.md](./monitoring/prometheus.md) |
| [monitoring/prometheus.md](./monitoring/prometheus.md)                   | Prometheus-specific configuration and access             | [monitoring/monitoring.md](./monitoring/monitoring.md), [monitoring/grafana.md](./monitoring/grafana.md)       |
| [monitoring/script-health-fixes.md](./monitoring/script-health-fixes.md) | Summary of script fixes and infrastructure health issues | [monitoring/grafana.md](./monitoring/grafana.md), [../scripts/README.md](../scripts/README.md)                 |

## Process Documentation

| Document                                                         | Purpose                                                        | Related Documents                                                                  |
| ---------------------------------------------------------------- | -------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [processes/ci-cd.md](./processes/ci-cd.md)                       | GitHub Actions CI/CD implementation                            | [infrastructure/container-deployment.md](./infrastructure/container-deployment.md) |
| [processes/github-workflows.md](./processes/github-workflows.md) | Automated monitoring, resource checking, and cleanup workflows | [scripts.md](./scripts.md), [processes/ci-cd.md](./processes/ci-cd.md)             |
| [processes/testing.md](./processes/testing.md)                   | Testing approach, coverage, and examples                       | [processes/ci-cd.md](./processes/ci-cd.md)                                         |
| [processes/audits.md](./processes/audits.md)                     | Infrastructure and codebase audit processes                    | [../audits/overview.md](../audits/overview.md)                                     |

## User Guides

| Document                                                     | Purpose                                    | Related Documents                                      |
| ------------------------------------------------------------ | ------------------------------------------ | ------------------------------------------------------ |
| [guides/local-development.md](./guides/local-development.md) | Setting up a local development environment | [processes/testing.md](./processes/testing.md)         |
| [guides/deployment-guide.md](./guides/deployment-guide.md)   | Complete system deployment instructions    | [processes/ci-cd.md](./processes/ci-cd.md)             |
| [guides/troubleshooting.md](./guides/troubleshooting.md)     | Common issues and resolution steps         | [monitoring/monitoring.md](./monitoring/monitoring.md) |

## Audit Documentation

| Document                                                                                                     | Purpose                                 | Related Documents                                                                                            |
| ------------------------------------------------------------------------------------------------------------ | --------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| [../audits/README.md](../audits/README.md)                                                                   | Audit directory overview                | [../audits/overview.md](../audits/overview.md)                                                               |
| [../audits/overview.md](../audits/overview.md)                                                               | Main index for all audit documentation  | [../audits/README.md](../audits/README.md), [processes/audits.md](./processes/audits.md)                     |
| [../audits/codebase/README.md](../audits/codebase/README.md)                                                 | Codebase audit reports index            | [../audits/templates/codebase-audit-template.md](../audits/templates/codebase-audit-template.md)             |
| [../audits/infrastructure/README.md](../audits/infrastructure/README.md)                                     | Infrastructure audit reports index      | [../audits/templates/infrastructure-audit-template.md](../audits/templates/infrastructure-audit-template.md) |
| [../audits/security/README.md](../audits/security/README.md)                                                 | Security audit reports index            | [../audits/templates/security-audit-template.md](../audits/templates/security-audit-template.md)             |
| [../audits/templates/audit-checklist.md](../audits/templates/audit-checklist.md)                             | General checklist for audit preparation | All audit templates                                                                                          |
| [../audits/templates/codebase-audit-template.md](../audits/templates/codebase-audit-template.md)             | Template for codebase audits            | [../audits/codebase/README.md](../audits/codebase/README.md)                                                 |
| [../audits/templates/infrastructure-audit-template.md](../audits/templates/infrastructure-audit-template.md) | Template for infrastructure audits      | [../audits/infrastructure/README.md](../audits/infrastructure/README.md)                                     |
| [../audits/templates/security-audit-template.md](../audits/templates/security-audit-template.md)             | Template for security audits            | [../audits/security/README.md](../audits/security/README.md)                                                 |

## Script Documentation

| Document                                     | Purpose                        | Related Documents                            |
| -------------------------------------------- | ------------------------------ | -------------------------------------------- |
| [../scripts/README.md](../scripts/README.md) | Scripts directory overview     | [scripts.md](./scripts.md)                   |
| [scripts.md](./scripts.md)                   | Detailed scripts documentation | [../scripts/README.md](../scripts/README.md) |

## Documentation Standards

| Document                                                                                         | Purpose                                      | Related Documents                                          |
| ------------------------------------------------------------------------------------------------ | -------------------------------------------- | ---------------------------------------------------------- |
| [documentation-style-guide.md](./documentation-style-guide.md)                                   | Standards for documentation format and style | [documentation-inventory.md](./documentation-inventory.md) |
| [templates/general-documentation-template.md](./templates/general-documentation-template.md)     | Template for general documentation           | -                                                          |
| [templates/component-documentation-template.md](./templates/component-documentation-template.md) | Template for component documentation         | -                                                          |
| [templates/process-documentation-template.md](./templates/process-documentation-template.md)     | Template for process documentation           | -                                                          |
| [assets/README.md](./assets/README.md)                                                           | Guidelines for using documentation assets    | -                                                          |

## Documentation Gaps

Based on the inventory, the following documentation gaps have been identified:

1. **Architecture Diagrams**: Visual representations of the system architecture would be valuable
2. **User Guide**: End-user documentation for the dashboard and monitoring system

## Next Steps

1. Create architecture diagrams for key components
2. Develop end-user documentation for the monitoring dashboard
3. Update cross-references in all documents to reflect the new directory structure

---

**Last Updated**: 2025-03-16
**Version**: 1.3
