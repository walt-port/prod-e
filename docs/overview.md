# Project Overview

**Version:** 1.3
**Last Updated:** [Current Date - will be filled by system]
**Owner:** DevOps Team

## Overview

This document provides a high-level overview of the Production Experience Showcase (prod-e) project. The primary goal is to demonstrate practical DevOps/SRE skills by building and maintaining a realistic cloud application environment on AWS. It includes infrastructure provisioning via Infrastructure as Code, CI/CD pipelines, containerized services, and operational monitoring capabilities, serving as a portfolio piece addressing the common "production experience" requirement.

## Architecture Summary

The project utilizes AWS infrastructure deployed in the `us-west-2` region, provisioned using CDKTF (TypeScript). Key components include:

- **Networking**: A multi-AZ VPC with public and private subnets, NAT Gateway, and Security Groups.
- **Load Balancing**: An Application Load Balancer (ALB) distributing traffic to backend services.
- **Compute**: ECS Fargate running containerized services:
  - `prod-e-backend`: A Node.js/Express application.
  - `prod-e-grafana-service`: Grafana instance (requires configuration).
  - `prod-e-prometheus-service`: Prometheus instance (requires configuration).
- **Database**: An RDS PostgreSQL instance (`prod-e-db`) in a multi-AZ configuration.
- **Secrets**: AWS Secrets Manager securely stores database credentials and other secrets.
- **Monitoring**: Foundational monitoring uses AWS CloudWatch. Prometheus and Grafana are deployed for advanced metrics and visualization but require further configuration to scrape application/service metrics.

_(Note: Specific diagrams should be updated or added here once accurate representations are available.)_

## Technology Stack Highlights

- **Cloud**: AWS (VPC, EC2, ECS, Fargate, RDS, ALB, S3, CloudWatch, Secrets Manager)
- **Infrastructure as Code**: CDKTF (TypeScript), Terraform
- **Backend**: Node.js, Express
- **Database**: PostgreSQL
- **Containers**: Docker
- **Monitoring**: Prometheus, Grafana, CloudWatch (Basic)
- **CI/CD & Automation**: GitHub Actions

For more details, refer to the [Technology Stack documentation](./my-stack.md). _(Self-note: Need to verify/create `my-stack.md` based on `.mdc` file)_

## Automation

Key processes are automated using GitHub Actions:

- **CI/CD Pipeline**: Builds, tests, and deploys the backend application and infrastructure changes.
- **Resource Checks**: Periodically verifies the status of critical AWS resources (`resource_check.sh`).
- **Health Monitoring**: Performs basic health checks against service endpoints.

See the [Processes Documentation](./processes/README.md) for details on workflows.

## Documentation Structure

This overview serves as an entry point. Detailed documentation is organized into the following areas:

- **[Infrastructure](./infrastructure/README.md)**: Detailed configuration of AWS resources (VPC, ECS, RDS, ALB, etc.).
- **[Processes](./processes/README.md)**: Workflows for CI/CD, monitoring, resource management, and audits.
- **[Application](./backend/README.md)**: Backend service specifics (API, configuration). _(Self-note: Check if frontend docs exist/are needed)_
- **[Guides](./guides/README.md)**: Setup, deployment, and troubleshooting guides.
- **[Monitoring](./monitoring/README.md)**: Details on the deployed monitoring tools and configuration state.

Refer to the main [Documentation Overview](../../DOCUMENTATION.md) for a comprehensive index.

## Related Documentation

- [Root README](../../README.md)
- [Documentation Overview](../../DOCUMENTATION.md)

---

**Last Updated**: [Current Date - will be filled by system]
**Version**: 1.3
