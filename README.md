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

<details>
<summary>🌩️ Infrastructure & Cloud</summary>

- AWS (Amazon Web Services)
- CDKTF (Cloud Development Kit for Terraform)
- Terraform
- Docker & Container Technologies
- IAM (Identity and Access Management)
</details>

<details>
<summary>🖥️ Backend</summary>

- Node.js
- Express
- PostgreSQL
- ECS Fargate
</details>

<details>
<summary>🔍 Monitoring & Observability</summary>

- Prometheus
- Grafana
- CloudWatch
</details>

<details>
<summary>🧠 AI Assistance</summary>

- Claude
- Cursor
- Grok
</details>

## 🏗️ Infrastructure Components

<details>
<summary>AWS Cloud Infrastructure</summary>

#### Networking

- VPC with DNS support and DNS hostnames
- Public & private subnets across multiple AZs
- Internet Gateway & NAT Gateway
- Route tables and security groups
- Application Load Balancer (ALB)

#### Compute & Containers

- ECS Fargate for serverless container orchestration
- Task definitions with Node.js application
- IAM roles and execution policies

#### Data Storage

- RDS PostgreSQL database
- Multi-AZ subnet groups
- Database security configuration

#### Monitoring & Observability

- Prometheus metrics collection (in progress)
- Grafana dashboards (planned)
- CloudWatch integration
</details>

<details>
<summary>Application Components</summary>

#### Backend API

- Node.js/Express REST API
- Health check endpoints
- Prometheus metrics endpoint
- Database connectivity

#### Frontend (Planned)

- React/TypeScript dashboard
- Real-time metrics visualization
- Responsive design
</details>

## 🏛️ Infrastructure Design

The infrastructure is deployed across multiple availability zones (us-west-2a and us-west-2b) for high availability. The design includes:

- Public subnets in two AZs with direct internet access through an Internet Gateway
- Private subnets in two AZs for ECS Fargate services and RDS
- NAT Gateway in the public subnet allowing private resources to access the internet
- Application Load Balancer spanning multiple AZs for fault tolerance
- RDS PostgreSQL database with a subnet group covering multiple AZs

### 🆕 Recent Improvements

- Application Load Balancer now spans both us-west-2a and us-west-2b
- RDS database subnet group includes subnets in both us-west-2a and us-west-2b
- PostgreSQL username was updated to comply with reserved word restrictions
- NAT Gateway added to enable internet access from private subnets
- ECS task health checks optimized to use Node.js instead of curl
- ALB target group health check path updated to use /health endpoint
- Backend API enhanced with database logging for all non-metric endpoints

## 🧪 Comprehensive Testing

This project features a robust testing approach to ensure reliability and quality. All tests are available in the repository for review and demonstration purposes.

### Testing Locations

- **Infrastructure Tests**: Located in `__tests__/` directory
- **Backend API Tests**: Located in `backend/tests/` directory

### Test Coverage & Approach

<details>
<summary>📊 Test Statistics & Details</summary>

Current test coverage metrics:

| Metric     | Coverage |
| ---------- | -------- |
| Statements | 87.01%   |
| Branches   | 75%      |
| Functions  | 55.55%   |
| Lines      | 86.84%   |

Our testing philosophy emphasizes:

- **Isolation**: Each test is independent with no shared state
- **Mocking**: External services are properly mocked for reliable testing
- **Comprehensiveness**: All critical functionality has test coverage
- **Readability**: Tests serve as documentation for the codebase
</details>

<details>
<summary>🔬 Test Categories</summary>

- **API endpoints**: Validates response codes, content types, and payloads
- **Health checks**: Tests application health reporting and database connectivity
- **Metrics collection**: Verifies Prometheus metrics generation
- **Environment variables**: Tests configuration handling
- **Database connections**: Tests connection management and error handling
- **Docker container**: Validates container configuration
</details>

<details>
<summary>🛠️ Testing Framework</summary>

- **Jest**: Primary test runner and assertion library
- **Supertest**: HTTP endpoint testing
- **Mocks**: Custom mocks for PostgreSQL, Prometheus clients, and other external dependencies
- **Environment Isolation**: Tests run in isolated environments to prevent interference
</details>

<details>
<summary>▶️ Running Tests</summary>

```bash
# Run all backend tests
cd backend && npm test

# Run tests in watch mode (for development)
cd backend && npm run test:watch

# Generate test coverage report
cd backend && npm run test:coverage

# Run infrastructure tests
npm test
```

Detailed testing documentation is available in the `docs/testing.md` file.

</details>

## ⏱️ Implementation Progress

The project is being implemented over a 4-day timeline:

- ✅ **Day 1**: Infrastructure Setup

  - VPC, subnets, and networking components
  - RDS PostgreSQL database
  - ECS Fargate cluster and service
  - Application Load Balancer

- ✅ **Day 2**: Backend Services (Partial)

  - Node.js/Express API implementation
  - Database connectivity
  - Health check endpoints
  - Metrics endpoint for Prometheus
  - Database logging middleware

- 🔄 **Day 2 Continued**: Monitoring Setup (In Progress)

  - Prometheus server implementation
  - Grafana dashboard setup
  - Alert configuration

- ⏳ **Day 3**: Frontend Dashboard

  - React/TypeScript dashboard
  - Metrics visualization
  - Real-time updates

- ⏳ **Day 4**: CI/CD & Polish
  - GitHub Actions for CI/CD
  - Final testing and documentation
  - Project demonstration

## 📋 Prerequisites

- Node.js (v14+)
- Terraform CLI
- CDKTF CLI
- AWS CLI configured with appropriate credentials
- Docker (for local container development)

## 🔧 Installation & Usage

```bash
# Install dependencies
npm install

# Generate CDKTF providers
cdktf get
```

<details>
<summary>📝 Detailed Usage Instructions</summary>

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

</details>

<details>
<summary>📁 Project Structure</summary>

- `main.ts` - Main CDKTF code that defines the infrastructure
- `cdktf.json` - CDKTF configuration file
- `package.json` - Node.js package configuration
- `tsconfig.json` - TypeScript configuration
- `docs/` - Project documentation (see Documentation section below)
- `backend/` - Node.js/Express API service
- `frontend/` - React/TypeScript frontend (to be implemented)
</details>

<details>
<summary>⚙️ Customization</summary>

To modify the infrastructure:

1. Update the configuration in the `config` object in `main.ts`
2. Add or modify AWS resources in the `MyStack` class
3. Run `npm run synth` to generate updated Terraform configuration
</details>

## 💰 Cost Considerations

This project is designed to be cost-effective for demonstration purposes with an estimated monthly cost of ~$45-50.

<details>
<summary>Detailed Cost Breakdown</summary>

- ECS Fargate: ~$10
- RDS PostgreSQL: ~$15
- Application Load Balancer: ~$16
- NAT Gateway: ~$4.5 (plus data processing)
- Data Transfer: ~$1-2

Resources can be shut down after demonstration to avoid ongoing costs.

</details>

## ⚠️ Known Issues and Resolutions

Below is a summary of issues encountered and their solutions.

<details>
<summary>View Resolved Issues</summary>

1. **RDS DB Subnet Group Requirement**: AWS requires RDS instances to have subnet groups spanning at least two AZs, even for single-AZ database deployments. We resolved this by adding a second private subnet in us-west-2b.

2. **PostgreSQL Reserved Words**: 'admin' is a reserved word in PostgreSQL and cannot be used as a master username. We changed this to 'dbadmin'.

3. **Private Subnet Internet Access**: ECS tasks in private subnets couldn't access ECR to pull Docker images. We fixed this by adding a NAT Gateway to provide internet access for resources in private subnets.

4. **Container Health Check Configuration**: The ECS task definition health check used curl, which wasn't available in the container. We changed it to use a Node.js script instead.

5. **ALB Health Check Path**: The ALB target group was checking the root path ('/') instead of the dedicated health endpoint. We updated it to use the '/health' endpoint.

6. **Test Environment Isolation**: Initial test failures occurred due to shared state between tests. We resolved this by implementing proper test isolation using Jest's `beforeEach` and `afterEach` hooks, ensuring each test starts with a clean state.

7. **Mock Database Connections**: Tests were failing intermittently due to improper mocking of PostgreSQL connections. We fixed this by implementing a more robust mocking strategy that properly handles connection states and error scenarios.
</details>

## 📚 Documentation

<details>
<summary>Core Infrastructure Documentation</summary>

- [Overview and Index](docs/overview.md) - Main documentation hub
- [Network Architecture](docs/network-architecture.md) - VPC, subnets, and connectivity
- [Load Balancer](docs/load-balancer.md) - ALB configuration and routing
- [Multi-AZ Strategy](docs/multi-az-strategy.md) - High availability approach
</details>

<details>
<summary>Services Documentation</summary>

- [RDS Database](docs/rds-database.md) - PostgreSQL configuration
- [ECS Service](docs/ecs-service.md) - Container orchestration and health checks
- [Container Deployment](docs/container-deployment.md) - Docker and ECR details
</details>

<details>
<summary>Implementation & Testing</summary>

- [Monitoring Implementation](docs/monitoring.md) - Prometheus and Grafana setup
- [Testing Documentation](docs/testing.md) - Testing approach and coverage
</details>
