# Documentation Inventory

**Version:** 1.5
**Last Updated:** March 16, 2025
**Owner:** DevOps Team

This document provides a complete inventory of all documentation files in the project. It serves as a reference to help locate specific documentation and identify gaps in documentation coverage.

## Infrastructure Documentation

| Document Title        | File Path                                  | Description                                                           | Related Documents                           |
| --------------------- | ------------------------------------------ | --------------------------------------------------------------------- | ------------------------------------------- |
| Infrastructure        | docs/infrastructure.md                     | Overview of modular infrastructure components and architecture        | All infrastructure documents                |
| Refactoring Summary   | docs/infrastructure/refactoring-summary.md | Summary of infrastructure code refactoring from monolithic to modular | infrastructure.md                           |
| Architecture Overview | infrastructure/architecture-overview.md    | High-level architectural design and component relationships           | network-architecture.md, load-balancer.md   |
| Network Architecture  | infrastructure/network-architecture.md     | VPC, subnets, security groups, and network flow                       | architecture-overview.md                    |
| Load Balancer         | infrastructure/load-balancer.md            | Application Load Balancer configuration, target groups, and listeners | network-architecture.md, ecs-service.md     |
| RDS Database          | infrastructure/rds-database.md             | RDS instance configuration, subnet groups, security, and backups      | network-architecture.md, database-config.md |
| ECS Service           | infrastructure/ecs-service.md              | ECS cluster, task definitions, services, and scaling                  | container-deployment.md, load-balancer.md   |
| Container Deployment  | infrastructure/container-deployment.md     | Container build process, ECR repositories, and deployment             | ecs-service.md                              |
| Remote State          | infrastructure/remote-state.md             | S3 state storage, DynamoDB locking, and state management              | architecture-overview.md                    |
| Budget Analysis       | infrastructure/ongoing-budget.md           | Cost analysis, budget considerations, and optimization                | resource-tagging.md                         |
| Resource Tagging      | infrastructure/resource-tagging.md         | Tagging strategy, implementation, and enforcement                     | ongoing-budget.md                           |

## Process Documentation

| Document Title          | File Path                            | Description                                                    | Related Documents                               |
| ----------------------- | ------------------------------------ | -------------------------------------------------------------- | ----------------------------------------------- |
| CI/CD Process           | processes/ci-cd.md                   | Continuous Integration and Deployment workflow                 | github-workflows.md                             |
| GitHub Workflows        | processes/github-workflows.md        | Automated monitoring, resource checking, and cleanup workflows | ci-cd.md, aws-resource-management.md            |
| AWS Resource Management | processes/aws-resource-management.md | AWS resource provisioning, monitoring, compliance, and cleanup | github-workflows.md, monitoring-setup.md        |
| Monitoring Setup        | processes/monitoring-setup.md        | Monitoring infrastructure and practices                        | aws-resource-management.md, github-workflows.md |
| Testing Strategy        | processes/testing.md                 | Testing approach, methodologies, and implementation            | ci-cd.md                                        |
| Audit Process           | processes/audits.md                  | Infrastructure and codebase audit processes                    | aws-resource-management.md                      |

## Application Documentation

| Document Title      | File Path              | Description                                                   | Related Documents    |
| ------------------- | ---------------------- | ------------------------------------------------------------- | -------------------- |
| API Reference       | api/api-reference.md   | API endpoints, parameters, responses, and examples            | backend/services.md  |
| Frontend Components | frontend/components.md | Frontend component documentation, usage, and examples         | api/api-reference.md |
| Backend Services    | backend/services.md    | Backend service documentation, dependencies, and interactions | api/api-reference.md |
| Database Schema     | database/schema.md     | Database schema, relationships, and indices                   | backend/services.md  |

## User and Administrative Guides

| Document Title      | File Path                   | Description                                      | Related Documents          |
| ------------------- | --------------------------- | ------------------------------------------------ | -------------------------- |
| User Guide          | guides/user-guide.md        | End-user documentation for application usage     | api/api-reference.md       |
| Administrator Guide | guides/admin-guide.md       | System administration guide                      | guides/deployment-guide.md |
| Deployment Guide    | guides/deployment-guide.md  | Step-by-step guide for deploying the application | processes/ci-cd.md         |
| Local Development   | guides/local-development.md | Setting up a local development environment       | guides/deployment-guide.md |
| Troubleshooting     | guides/troubleshooting.md   | Common issues and resolution steps               | guides/admin-guide.md      |

## Documentation Governance

| Document Title          | File Path                         | Description                                  | Related Documents          |
| ----------------------- | --------------------------------- | -------------------------------------------- | -------------------------- |
| Documentation Overview  | DOCUMENTATION.md                  | Overview of all documentation                | documentation-inventory.md |
| Documentation Inventory | docs/documentation-inventory.md   | Inventory of all documentation files         | DOCUMENTATION.md           |
| Style Guide             | docs/documentation-style-guide.md | Standards for documentation format and style | documentation-inventory.md |

## Documentation Format

All documentation follows these standards:

1. Written in Markdown format
2. Includes version information and last updated date
3. Follows the project documentation style guide
4. Cross-references related documentation
5. Includes relevant diagrams and visuals where appropriate

## Document Maintenance

The documentation inventory is updated when:

1. New documentation is added
2. Existing documentation is updated substantially
3. Documentation is removed or consolidated
4. Related documents change

---

**Last Updated**: 2025-03-16
**Version**: 1.5
