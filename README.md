# 🚀 The Production Experience Showcase (prod-e)

[![Build Status](https://github.com/walt-port/prod-e/actions/workflows/deploy.yml/badge.svg)](https://github.com/walt-port/prod-e/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Infrastructure: AWS](https://img.shields.io/badge/Infrastructure-AWS-orange)](https://aws.amazon.com/)

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

![Monitoring Dashboard](docs/assets/images/ui/monitoring-dashboard.png)

For detailed information about the monitoring setup, see our [Monitoring Documentation](docs/monitoring/README.md).

## 📚 Documentation

All project documentation is organized by category for easier navigation:

- **📂 [Infrastructure](docs/infrastructure/)** - Network architecture, AWS resources, state management
- **📂 [Monitoring](docs/monitoring/)** - Prometheus, Grafana, metrics
- **📂 [Processes](docs/processes/)** - CI/CD, deployment, operations
- **📂 [Guides](docs/guides/)** - Setup, troubleshooting, development
- **📄 [Documentation Index](docs/documentation-inventory.md)** - Complete listing of all documents

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

- **Resource Check** (`scripts/resource_check.sh`) - Check status of AWS resources
- **Teardown** (`scripts/teardown.py`) - Destroy infrastructure with detailed control
- **Build and Push** (`scripts/build-and-push.sh`) - Build and push Docker images

Example usage:

```bash
# Check AWS resources status
./scripts/resource_check.sh

# Teardown infrastructure
python scripts/teardown.py --dry-run
```

</details>

## 💰 Cost Considerations

This project is designed with cost efficiency in mind, with current estimated costs at ~$99/month.

For a detailed breakdown and optimization strategies, see [AWS Budget Analysis](docs/processes/ongoing-budget.md).

## 🤝 Contributing

Contributions are welcome! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
