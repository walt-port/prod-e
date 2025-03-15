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
<summary>☁️ AWS Cloud Infrastructure</summary>

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

- ✅ Prometheus metrics collection and server
- ⏳ Grafana dashboards (coming next)
- CloudWatch integration
</details>

<details>
<summary>📦 Application Components</summary>

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

The infrastructure is deployed across multiple availability zones (us-west-2a and us-west-2b) for high availability with a comprehensive monitoring stack. The design includes:

- Public subnets in two AZs with direct internet access through an Internet Gateway
- Private subnets in two AZs for ECS Fargate services and RDS
- NAT Gateway in the public subnet allowing private resources to access the internet
- Application Load Balancer spanning multiple AZs for fault tolerance
- RDS PostgreSQL database with a subnet group covering multiple AZs
- Prometheus metrics collection deployed on ECS Fargate
- Remote state backend with S3 for state storage and DynamoDB for state locking
- CI/CD pipeline automation with GitHub Actions for consistent deployments

<details>
<summary>🆕 Recent Improvements</summary>

- Application Load Balancer now spans both us-west-2a and us-west-2b
- RDS database subnet group includes subnets in both us-west-2a and us-west-2b
- PostgreSQL username was updated to comply with reserved word restrictions
- NAT Gateway added to enable internet access from private subnets
- ECS task health checks optimized to use Node.js instead of curl
- ALB target group health check path updated to use /health endpoint
- Backend API enhanced with database logging for all non-metric endpoints
- Remote state backend implemented with S3 and DynamoDB for better team collaboration
- Prometheus server deployed on ECS Fargate for metrics collection
- CI/CD pipeline enhanced with automated testing and container image validation
- Budget analysis documentation created with detailed current and projected costs
- Container tests updated to support both `--only=production` and `--omit=dev` syntax
- Implementation plan refined and updated for Grafana deployment with cost optimization
- ECS task definitions optimized for resource efficiency and cost management
- Documentation structure improved with phase-based implementation progress tracking
</details>

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

The project follows a phased implementation approach:

<details>
<summary>✅ Phase 1: Infrastructure Setup</summary>

- **Networking**

  - VPC with DNS support and hostnames
  - Public & private subnets across multiple AZs (us-west-2a and us-west-2b)
  - Internet Gateway for public subnet connectivity
  - NAT Gateway for private subnet internet access
  - Route tables and security groups

- **Data Storage**

  - RDS PostgreSQL database
  - Multi-AZ subnet group for database resilience
  - Security group configuration for database access

- **Compute & Container Management**

  - ECS Fargate cluster
  - Task definitions and IAM roles/policies
  - Application Load Balancer spanning multiple AZs
  - Target groups with health checks

- **Infrastructure as Code**
  - Remote state backend with S3
  - State locking with DynamoDB
  - IAM policies for state management
  </details>

<details>
<summary>✅ Phase 2: Backend Services & Monitoring</summary>

- **Node.js/Express API**

  - Health check endpoints for monitoring
  - Database connectivity and CRUD operations
  - Prometheus metrics endpoint
  - Database logging middleware
  - Error handling and request validation

- **Monitoring Setup**

  - Prometheus server on ECS Fargate
  - Metrics collection from backend service
  - Custom application metrics
  - Node.js runtime metrics
  - Container metrics

- **CI/CD Pipeline**
  - GitHub Actions workflow configuration
  - Automated testing for backend code
  - Docker image building and ECR push
  - Automated infrastructure deployment
  - Test validation in pipeline
  </details>

<details>
<summary>🔄 Phase 3: Grafana Implementation (In Progress)</summary>

- **Planned Components**

  - Grafana on ECS Fargate (single-AZ for cost efficiency)
  - EFS for persistent dashboard storage
  - AWS Secrets Manager for credentials
  - ALB path-based routing for access
  - Backup system using Lambda and S3

- **Dashboard & Visualization**
  - System metrics dashboard
  - Node.js application metrics dashboard
  - RDS database metrics dashboard
  - HTTP request metrics dashboard
  - Alerting configuration
  </details>

<details>
<summary>⏳ Phase 4: Frontend & Documentation (Planned)</summary>

- **React/TypeScript Frontend**

  - Dashboard interface for metrics
  - Real-time data visualization
  - Health status monitoring
  - Responsive design

- **Final Documentation & Polish**
  - Architecture diagrams
  - Operational documentation
  - Setup guides
  - Troubleshooting documentation
  - Security best practices
  </details>

## 📋 Prerequisites

- Node.js (v14+)
- Terraform CLI
- CDKTF CLI
- AWS CLI configured with appropriate credentials
- Docker (for local container development)

## 🔧 Installation & Usage

<details>
<summary>📝 Detailed Usage Instructions</summary>

```bash
# Install dependencies
npm install

# Generate CDKTF providers
cdktf get

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

### GitHub Actions CI/CD Setup

To use the GitHub Actions CI/CD pipeline, you need to add AWS credentials to your GitHub repository:

1. Go to your GitHub repository > Settings > Secrets and variables > Actions
2. Add two repository secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

These credentials must have permissions for all the AWS services used in this project (ECR, ECS, CloudWatch, etc.).

> **Security Note**: GitHub secrets are encrypted and not visible to other users. They are only used during workflow runs and are masked in logs.

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

This project is designed with cost efficiency in mind. The current estimated monthly cost is approximately ~$99/month.

<details>
<summary>💵 Cost Summary</summary>

- Current infrastructure costs include ECS Fargate tasks, RDS PostgreSQL, Application Load Balancer, NAT Gateway, and other supporting services
- The planned Grafana implementation will add approximately ~$15/month
- For a detailed breakdown of all costs, optimization strategies, and future projections, see [AWS Budget Analysis](docs/ongoing_budget.md)
- Resources can be shut down after demonstration to avoid ongoing costs

</details>

## ⚠️ Known Issues and Resolutions

Below is a summary of issues encountered and their solutions.

<details>
<summary>🔧 View Resolved Issues</summary>

1. **RDS DB Subnet Group Requirement**: AWS requires RDS instances to have subnet groups spanning at least two AZs, even for single-AZ database deployments. We resolved this by adding a second private subnet in us-west-2b.

2. **Private Subnet Internet Access**: ECS tasks in private subnets couldn't access ECR to pull Docker images. We fixed this by adding a NAT Gateway to provide internet access for resources in private subnets.

3. **Container Health Check Configuration**: The ECS task definition health check used curl, which wasn't available in the container. We changed it to use a Node.js script instead.

4. **ALB Health Check Path**: The ALB target group was checking the root path ('/') instead of the dedicated health endpoint. We updated it to use the '/health' endpoint.

5. **Test Environment Isolation**: Initial test failures occurred due to shared state between tests. We resolved this by implementing proper test isolation using Jest's `beforeEach` and `afterEach` hooks, ensuring each test starts with a clean state.

6. **Mock Database Connections**: Tests were failing intermittently due to improper mocking of PostgreSQL connections. We fixed this by implementing a more robust mocking strategy that properly handles connection states and error scenarios.
</details>

## 📚 Documentation

<details>
<summary>🏢 Core Infrastructure Documentation</summary>

- [Overview and Index](docs/overview.md) - Main documentation hub
- [Network Architecture](docs/network-architecture.md) - VPC, subnets, and connectivity
- [Load Balancer](docs/load-balancer.md) - ALB configuration and routing
- [Multi-AZ Strategy](docs/multi-az-strategy.md) - High availability approach
- [Remote State Backend](docs/remote_state.md) - S3 and DynamoDB for Terraform state
</details>

<details>
<summary>🚀 Services Documentation</summary>

- [RDS Database](docs/rds-database.md) - PostgreSQL configuration
- [ECS Service](docs/ecs-service.md) - Container orchestration and health checks
- [Container Deployment](docs/container-deployment.md) - Docker and ECR details
</details>

<details>
<summary>📋 Implementation & Testing</summary>

- [Monitoring Implementation](docs/monitoring.md) - Prometheus and Grafana setup
- [Testing Documentation](docs/testing.md) - Testing approach and coverage
- [CI/CD Implementation](docs/ci-cd.md) - GitHub Actions workflow for continuous deployment
</details>

<details>
<summary>🛠️ Utility Scripts</summary>

The project includes several utility scripts to help with management and monitoring:

- **Resource Check Script** (`scripts/resource_check.sh`):

  - Provides comprehensive status checks of all AWS resources
  - Color-coded output for easy identification of issues
  - Covers VPC, RDS, ECS, ALB, ECR, Terraform state, and Prometheus

- **Teardown Script** (`scripts/teardown.py`):

  - Alternative to `npm run destroy` with more detailed control
  - Shows resources that will be deleted before taking action
  - Handles resources in the correct dependency order

- **Build and Push Script** (`scripts/build-and-push.sh`):
  - Builds and pushes Docker images to ECR
  - Streamlines the container deployment process

Usage:

```bash
# Check status of all AWS resources
./scripts/resource_check.sh

# Teardown infrastructure with detailed control
python scripts/teardown.py --dry-run

# Build and push Docker images
./scripts/build-and-push.sh
```

For detailed documentation on these scripts, see [scripts/RESOURCE_CHECK.md](scripts/RESOURCE_CHECK.md).

</details>
