# 🚀 The Production Experience Showcase (prod-e)

A platform demonstrating DevOps/SRE skills by building a monitoring and alerting dashboard system with modern infrastructure practices. This project addresses the common "production experience" barrier in job searches by creating a practical, functional system with industry-standard technologies.

## 📋 Project Overview

This project implements a complete cloud infrastructure with monitoring capabilities:

- AWS infrastructure using the Cloud Development Kit for Terraform (CDKTF) with TypeScript
- Containerized backend services with ECS Fargate
- API service built with Node.js/Express
- PostgreSQL database for data storage
- Prometheus and Grafana for metrics collection and visualization
- Modern React/TypeScript frontend for the dashboard
- CI/CD automation with GitHub Actions

## 🛠️ Technology Stack

### 🌩️ Infrastructure & Cloud

- AWS (Amazon Web Services)
- CDKTF (Cloud Development Kit for Terraform)
- Terraform
- Docker & Container Technologies
- IAM (Identity and Access Management)

### 🖥️ Backend

- Node.js
- Express
- PostgreSQL
- ECS Fargate

### 🔍 Monitoring & Observability

- Prometheus
- Grafana
- CloudWatch

### 🧠 AI Assistance

- Claude
- Cursor
- Grok

## 🏗️ Infrastructure Components

This project sets up the following AWS resources:

### 🌐 Networking

- VPC with DNS support and DNS hostnames
- Public subnets in us-west-2a (10.0.1.0/24) and us-west-2b (10.0.3.0/24)
- Private subnets in us-west-2a (10.0.2.0/24) and us-west-2b (10.0.4.0/24)
- Internet Gateway for public internet access
- NAT Gateway in the public subnet for private subnet internet access
- Route tables with proper routing configuration
- Application Load Balancer for traffic management (spanning multiple AZs)

### 💻 Compute

- ECS Fargate for containerized services
- Single task with minimal resources (0.25 vCPU, 0.5GB memory)
- Containerized Node.js/Express API

### 💾 Data Storage

- RDS PostgreSQL instance (db.t3.micro) with subnet group spanning multiple AZs
- Prometheus time series database for metrics (to be implemented)

### 📊 Monitoring & Visualization

- Prometheus for metrics collection
- Grafana for dashboard visualization
- CloudWatch for AWS service monitoring

## 🏛️ Infrastructure Design

The infrastructure is deployed across multiple availability zones (us-west-2a and us-west-2b) for high availability. The design includes:

- Public subnets in two AZs with direct internet access through an Internet Gateway
- Private subnets in two AZs for ECS Fargate services and RDS
- NAT Gateway in the public subnet allowing private resources to access the internet
- Application Load Balancer spanning multiple AZs for fault tolerance
- RDS PostgreSQL database with a subnet group covering multiple AZs

### 🆕 Recent Improvements

The infrastructure was recently updated to support AWS requirements and best practices:

- Application Load Balancer now spans both us-west-2a and us-west-2b
- RDS database subnet group includes subnets in both us-west-2a and us-west-2b
- PostgreSQL username was updated to comply with reserved word restrictions
- NAT Gateway added to enable internet access from private subnets
- ECS task health checks optimized to use Node.js instead of curl

## 🧪 Testing

The project includes comprehensive testing to ensure reliability and quality:

### Backend Testing Framework

- Jest as the primary test runner and assertion library
- Supertest for HTTP endpoint testing
- Mocked external dependencies (PostgreSQL, Prometheus clients)

### Test Categories

- API endpoints: Validates response codes, content types, and payload structure
- Health checks: Ensures proper status reporting and database connection handling
- Metrics collection: Verifies Prometheus metrics generation and formatting
- Environment variables: Tests configuration from environment variables
- Database connections: Tests connection handling and error scenarios
- Docker container: Validates Dockerfile configuration and best practices

### Current Test Coverage

| Metric     | Coverage |
| ---------- | -------- |
| Statements | 87.01%   |
| Branches   | 75%      |
| Functions  | 55.55%   |
| Lines      | 86.84%   |

All tests are organized by functionality with detailed documentation available in the `docs/` directory.

## ⏱️ Implementation Timeline

The project is being implemented over a 4-day timeline:

1. **Day 1**: Infrastructure Setup (VPC, ALB, RDS, ECS)
2. **Day 2**: Backend Services & Monitoring (Node.js API, Prometheus, Grafana)
3. **Day 3**: Frontend Dashboard (React, TypeScript, metrics visualization)
4. **Day 4**: CI/CD, Testing & Polish (GitHub Actions, documentation)

## 📋 Prerequisites

- Node.js (v14+)
- Terraform CLI
- CDKTF CLI
- AWS CLI configured with appropriate credentials
- Docker (for local container development)

## 🔧 Installation

```bash
# Install dependencies
npm install

# Generate CDKTF providers
cdktf get
```

## 📝 Usage

```bash
# Synthesize Terraform configuration
npm run synth

# Deploy infrastructure
npm run deploy

# Destroy infrastructure
npm run destroy
```

### Running Tests

```bash
# Run all tests
cd backend && npm test

# Run tests in watch mode (for development)
cd backend && npm run test:watch

# Generate test coverage report
cd backend && npm run test:coverage
```

## 📁 Project Structure

- `main.ts` - Main CDKTF code that defines the infrastructure
- `cdktf.json` - CDKTF configuration file
- `package.json` - Node.js package configuration
- `tsconfig.json` - TypeScript configuration
- `docs/` - Project documentation
- `backend/` - Node.js/Express API service (to be added)
- `frontend/` - React/TypeScript frontend (to be added)

## ⚙️ Customization

To modify the infrastructure:

1. Update the configuration in the `config` object in `main.ts`
2. Add or modify AWS resources in the `MyStack` class
3. Run `npm run synth` to generate updated Terraform configuration

## 💰 Cost Considerations

This project is designed to be cost-effective for demonstration purposes:

- Estimated monthly cost: ~$45-50
- ECS Fargate: ~$10
- RDS PostgreSQL: ~$15
- Application Load Balancer: ~$16
- NAT Gateway: ~$4.5 (plus data processing)
- Data Transfer: ~$1-2

Resources can be shut down after demonstration to avoid ongoing costs.

## ⚠️ Known Issues and Resolutions

During deployment and testing, we encountered and resolved the following issues:

1. **RDS DB Subnet Group Requirement**: AWS requires RDS instances to have subnet groups spanning at least two AZs, even for single-AZ database deployments. We resolved this by adding a second private subnet in us-west-2b.

2. **PostgreSQL Reserved Words**: 'admin' is a reserved word in PostgreSQL and cannot be used as a master username. We changed this to 'dbadmin'.

3. **Private Subnet Internet Access**: ECS tasks in private subnets couldn't access ECR to pull Docker images. We fixed this by adding a NAT Gateway to provide internet access for resources in private subnets.

4. **Container Health Check Configuration**: The ECS task definition health check used curl, which wasn't available in the container. We changed it to use a Node.js script instead.

5. **Test Environment Isolation**: Initial test failures occurred due to shared state between tests. We resolved this by implementing proper test isolation using Jest's `beforeEach` and `afterEach` hooks, ensuring each test starts with a clean state.

6. **Mock Database Connections**: Tests were failing intermittently due to improper mocking of PostgreSQL connections. We fixed this by implementing a more robust mocking strategy that properly handles connection states and error scenarios.
