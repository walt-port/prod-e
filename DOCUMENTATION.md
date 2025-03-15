# Production Experience Showcase Documentation

## Overview

This document serves as the central index for all documentation in the Production Experience Showcase (prod-e) project. It provides organized access to documentation across different categories and serves as the starting point for navigating project documentation.

## Table of Contents

- [Getting Started](#getting-started)
- [Infrastructure Documentation](#infrastructure-documentation)
- [Monitoring & Observability](#monitoring--observability)
- [Process Documentation](#process-documentation)
- [Audit Documentation](#audit-documentation)
- [Scripts & Utilities](#scripts--utilities)
- [Documentation Standards](#documentation-standards)

## Getting Started

- [Project README](./README.md) - Project overview, technology stack, and implementation progress
- [Local Development Setup](./docs/local-development.md) - Setting up a local development environment
- [Deployment Guide](./docs/deployment-guide.md) - Complete system deployment instructions
- [Troubleshooting Guide](./docs/troubleshooting.md) - Common issues and resolution steps

## Infrastructure Documentation

- [Infrastructure Overview](./docs/overview.md) - Main index for infrastructure documentation
- [Network Architecture](./docs/network-architecture.md) - VPC, subnets, NAT Gateway, and routing
- [Load Balancer Configuration](./docs/load-balancer.md) - ALB, target groups, and listeners
- [RDS Database](./docs/rds-database.md) - RDS instance, security groups, and subnet groups
- [ECS Service](./docs/ecs-service.md) - ECS cluster, task definition, service, health checks
- [Multi-AZ Strategy](./docs/multi-az-strategy.md) - Multi-AZ implementation and future plans
- [Container Deployment](./docs/container-deployment.md) - ECR, Docker builds, and container deployment
- [Remote State Management](./docs/remote-state.md) - S3 remote state backend and DynamoDB state locking
- [Budget Analysis](./docs/ongoing-budget.md) - Budget analysis and cost management

## Monitoring & Observability

- [Monitoring Overview](./docs/monitoring.md) - Prometheus and Grafana implementation
- [Grafana Configuration](./docs/grafana.md) - Grafana-specific configuration and dashboards

## Process Documentation

- [CI/CD Pipeline](./docs/ci-cd.md) - GitHub Actions CI/CD implementation
- [Testing Strategy](./docs/testing.md) - Testing approach, coverage, and examples
- [Audit Process](./docs/audits.md) - Infrastructure and codebase audit processes

## Audit Documentation

- [Audit Overview](./audits/overview.md) - Main index for all audit documentation
- [Audit README](./audits/README.md) - Audit directory overview

### Audit Categories

- [Codebase Audits](./audits/codebase/README.md) - Codebase audit reports
- [Infrastructure Audits](./audits/infrastructure/README.md) - Infrastructure audit reports
- [Security Audits](./audits/security/README.md) - Security audit reports

### Audit Templates

- [Audit Checklist](./audits/templates/audit-checklist.md) - General checklist for audit preparation
- [Codebase Audit Template](./audits/templates/codebase-audit-template.md) - Template for codebase audits
- [Infrastructure Audit Template](./audits/templates/infrastructure-audit-template.md) - Template for infrastructure audits
- [Security Audit Template](./audits/templates/security-audit-template.md) - Template for security audits

## Scripts & Utilities

- [Scripts README](./scripts/README.md) - Scripts directory overview
- [Resource Check Documentation](./scripts/RESOURCE_CHECK.md) - Resource checking script documentation

## Documentation Standards

- [Documentation Inventory](./docs/documentation-inventory.md) - Inventory of all project documentation
- [Documentation Style Guide](./docs/documentation-style-guide.md) - Standards for documentation format and style

### Documentation Templates

- [General Documentation Template](./docs/templates/general-documentation-template.md) - Template for general documentation
- [Component Documentation Template](./docs/templates/component-documentation-template.md) - Template for component documentation
- [Process Documentation Template](./docs/templates/process-documentation-template.md) - Template for process documentation

---

**Last Updated**: 2025-03-15
**Version**: 1.0
