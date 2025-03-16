# 🚀 The Production Experience Showcase (prod-e)

[![Build Status](https://github.com/walt-port/prod-e/actions/workflows/deploy.yml/badge.svg)](https://github.com/walt-port/prod-e/actions/workflows/deploy.yml)
[![Project Status: Active](https://img.shields.io/badge/Project_Status-Active-success.svg)](https://github.com/walt-port/prod-e/actions)
[![Production Ready](https://img.shields.io/badge/Production-Ready-green.svg)](docs/processes/github-workflows.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Infrastructure: AWS](https://img.shields.io/badge/Infrastructure-AWS-orange)](https://aws.amazon.com/)
[![Documentation: Comprehensive](https://img.shields.io/badge/Documentation-Comprehensive-blueviolet)](docs/documentation-inventory.md)
[![Last Updated: March 2025](https://img.shields.io/badge/Last_Updated-March_2025-informational)](CHANGELOG.md)

A platform demonstrating DevOps/SRE skills by building a monitoring and alerting dashboard system with modern infrastructure practices. This project addresses the common "production experience" barrier in job searches by creating a practical, functional system with industry-standard technologies.

[Architecture Overview](#-architecture) | [Quick Start](#-quick-start) | [Tech Stack](#-technology-stack) | [Documentation](#-documentation) | [Testing](#-testing)

## 📋 Project Overview

This project implements a complete cloud infrastructure with monitoring capabilities:

- AWS infrastructure using the Cloud Development Kit for Terraform (CDKTF) with TypeScript
- Containerized backend services with ECS Fargate
- API service built with Node.js/Express
- PostgreSQL database for data storage
- Prometheus and Grafana for metrics collection and visualization
- Modern React/TypeScript frontend for the dashboard
- CI/CD automation with GitHub Actions

## ✅ Implementation Status

<table>
  <tr>
    <th>Component</th>
    <th>Status</th>
    <th>Details</th>
  </tr>
  <tr>
    <td>Infrastructure</td>
    <td>✅ Complete</td>
    <td>Multi-AZ AWS deployment with VPC, ECS, RDS, ALB</td>
  </tr>
  <tr>
    <td>Backend API</td>
    <td>✅ Complete</td>
    <td>Node.js/Express with health, metrics endpoints</td>
  </tr>
  <tr>
    <td>Database</td>
    <td>✅ Complete</td>
    <td>PostgreSQL 14.17 on RDS with multi-AZ subnet group</td>
  </tr>
  <tr>
    <td>Monitoring Stack</td>
    <td>✅ Complete</td>
    <td>Prometheus & Grafana with custom dashboards</td>
  </tr>
  <tr>
    <td>CI/CD Pipeline</td>
    <td>✅ Complete</td>
    <td>GitHub Actions with automated testing & deployment</td>
  </tr>
  <tr>
    <td>GitHub Workflows</td>
    <td>✅ Complete</td>
    <td>Health monitoring, resource checks, cleanup</td>
  </tr>
  <tr>
    <td>Frontend Dashboard</td>
    <td>⏳ Planned</td>
    <td>React/TypeScript UI (design specs ready)</td>
  </tr>
</table>

## 📢 Latest Updates

- **March 16, 2025**: Enhanced monitoring implementation with Phase 3 future plans
- **March 16, 2025**: Updated AWS budget analysis with current resource inventory
- **March 16, 2025**: Improved documentation with comprehensive GitHub Workflows section
- **March 16, 2025**: Added new visualization diagrams for monitoring and workflows
- **March 15, 2025**: Multi-AZ deployment successfully implemented across components

## 🚀 Quick Start

### Prerequisites

- Node.js (v14+)
- Terraform CLI
- CDKTF CLI
- AWS CLI configured with appropriate credentials
- Docker (for local container development)

### Installation

```bash
# Clone repository
git clone https://github.com/walt-port/prod-e.git
cd prod-e

# Install dependencies
npm install

# Generate CDKTF providers
cdktf get

# Synthesize Terraform configuration
npm run synth

# Deploy infrastructure
npm run deploy
```

For detailed setup instructions and development workflow, see our [Deployment Guide](docs/guides/deployment-guide.md) and [Local Development Guide](docs/guides/local-development.md).

## 🏗️ Architecture

The infrastructure is deployed across multiple availability zones (us-west-2a and us-west-2b) for high availability with a comprehensive monitoring stack:

![System Architecture Diagram](docs/assets/images/architecture/system-overview.png)

### Key Components

- **Networking**: VPC with public and private subnets across multiple AZs, Internet Gateway, NAT Gateway
- **Compute**: ECS Fargate for serverless container orchestration
- **Storage**: RDS PostgreSQL database with multi-AZ subnet groups
- **Monitoring**: Prometheus metrics collection, Grafana dashboards
- **Security**: IAM roles and policies, security groups, secrets management
- **Delivery**: CI/CD pipeline with GitHub Actions

For a detailed breakdown of the infrastructure, see [Infrastructure Documentation](docs/infrastructure/README.md).

## 🛠️ Technology Stack

<details>
<summary>🌩️ Infrastructure & Cloud</summary>

- **AWS** (Amazon Web Services)
- **CDKTF** (Cloud Development Kit for Terraform)
- **Terraform**
- **Docker & Container Technologies**
- **IAM** (Identity and Access Management)
</details>

<details>
<summary>🖥️ Backend</summary>

- **Node.js**
- **Express**
- **PostgreSQL**
- **ECS Fargate**
</details>

<details>
<summary>🔍 Monitoring & Observability</summary>

- **Prometheus**
- **Grafana**
- **CloudWatch**
</details>

<details>
<summary>🧪 Testing & CI/CD</summary>

- **Jest**
- **Supertest**
- **GitHub Actions**
</details>

## 📊 Monitoring

The project features a comprehensive monitoring stack:

- **Prometheus** for metrics collection and storage
- **Grafana** for visualization and dashboards
- **Custom metrics** for application performance monitoring
- **System metrics** for infrastructure health

<img src="docs/assets/images/monitoring-architecture.svg" alt="Monitoring Architecture" width="650">

For detailed information about the monitoring setup, see our [Monitoring Setup](docs/processes/monitoring-setup.md).

## 📚 Documentation Explorer

Our comprehensive documentation covers every aspect of the project, from infrastructure to operations:

<div style="display: flex; flex-wrap: wrap; gap: 15px; justify-content: center;">
<a href="docs/infrastructure/README.md" style="display: block; width: 200px; padding: 15px; text-align: center; background-color: #f8f9fa; border-radius: 8px; text-decoration: none; color: inherit;">
    <h3>🏗️ Infrastructure</h3>
    <p>Network architecture, AWS resources, multi-AZ setup</p>
</a>
<a href="docs/processes/monitoring-setup.md" style="display: block; width: 200px; padding: 15px; text-align: center; background-color: #f8f9fa; border-radius: 8px; text-decoration: none; color: inherit;">
    <h3>📊 Monitoring</h3>
    <p>Prometheus, Grafana, metrics collection</p>
</a>
<a href="docs/processes/github-workflows.md" style="display: block; width: 200px; padding: 15px; text-align: center; background-color: #f8f9fa; border-radius: 8px; text-decoration: none; color: inherit;">
    <h3>⚙️ GitHub Workflows</h3>
    <p>Health monitoring, resource checks, cleanup</p>
</a>
<a href="docs/processes/ci-cd.md" style="display: block; width: 200px; padding: 15px; text-align: center; background-color: #f8f9fa; border-radius: 8px; text-decoration: none; color: inherit;">
    <h3>🚀 CI/CD</h3>
    <p>Deployment, testing, automation</p>
</a>
</div>

### 🌟 Featured Documentation

<table>
  <tr>
    <td width="33%"><a href="docs/processes/github-workflows.md"><strong>🔄 GitHub Workflows</strong></a><br>Comprehensive documentation of automated workflows for monitoring, resource verification, and cleanup</td>
    <td width="33%"><a href="docs/processes/aws-resource-management.md"><strong>☁️ AWS Resource Management</strong></a><br>Detailed guide to resource provisioning, tagging, compliance, and cleanup</td>
    <td width="33%"><a href="docs/infrastructure/ongoing-budget.md"><strong>💰 AWS Budget Analysis</strong></a><br>Current costs, optimizations, and resource inventory</td>
  </tr>
</table>

![GitHub Workflows Architecture](docs/assets/images/workflows/workflows-diagram.svg)

### 📑 Documentation Map

- **📂 [Infrastructure](docs/infrastructure/)** - Network architecture, AWS resources, state management
- **📂 [Processes](docs/processes/)** - CI/CD, deployment, operations, monitoring
- **📂 [Guides](docs/guides/)** - Setup, troubleshooting, development
- **📂 [Frontend](docs/frontend/)** - UI components, state management (planned)
- **📂 [Backend](docs/backend/)** - API documentation, services
- **📄 [Documentation Inventory](docs/documentation-inventory.md)** - Complete listing of all documents

For a high-level overview of the project, refer to [Project Overview](docs/overview.md).

## 🧪 Testing

This project features a robust testing approach to ensure reliability and quality:

- **API endpoint tests** validate response codes and payloads
- **Health check tests** verify application health reporting
- **Metrics collection tests** confirm proper metric generation
- **Infrastructure tests** validate CDKTF configurations

To run tests:

```bash
# Run API tests
cd backend && npm test

# Run infrastructure tests
npm test
```

For detailed information about our testing approach, see [Testing Documentation](docs/processes/testing.md).

## 🔧 Development Tools

The project includes several utility scripts to help with development and operations:

<details>
<summary>🛠️ Available Scripts</summary>

- **Resource Check** (`scripts/monitoring/resource_check.sh`) - Check status of AWS resources
- **Health Monitoring** (`scripts/monitoring/monitor-health.sh`) - Monitor service health
- **Cleanup Resources** (`scripts/maintenance/cleanup-resources.sh`) - Clean up unused resources
- **Teardown** (`scripts/maintenance/teardown.py`) - Destroy infrastructure with detailed control
- **Build and Push** (`scripts/deployment/build-and-push.sh`) - Build and push Docker images

Example usage:

```bash
# Check AWS resources status
./scripts/monitoring/resource_check.sh

# Monitor health of services
./scripts/monitoring/monitor-health.sh

# Clean up resources (dry run)
./scripts/maintenance/cleanup-resources.sh
```

</details>

## 💰 Cost Considerations

This project is designed with cost efficiency in mind:

- **Current Monthly Cost**: ~$124.20/month
- **After Optimizations**: ~$95.70-$100.20/month
- **With Future Enhancements**: ~$108-$113/month

For a detailed breakdown of costs, resource inventory, and optimization strategies, see [AWS Budget Analysis](docs/infrastructure/ongoing-budget.md).

## 🤝 Contributing

Contributions are welcome! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
<strong>Ready for Production Use</strong><br>
Last Updated: March 16, 2025
</div>
