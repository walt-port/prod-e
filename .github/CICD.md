# GitHub Actions CI/CD

This directory contains GitHub Actions workflow configurations for continuous integration and deployment of the Production Experience Showcase (prod-e) project.

## Workflows

### Deploy (`deploy.yml`)

This workflow automates the build, test, and deployment process whenever changes are pushed to the `main` branch or when manually triggered.

#### Workflow Steps:

1. **Checkout Code**: Retrieves the latest code from the repository
2. **Setup Node.js**: Installs Node.js 18.x with npm caching enabled
3. **Setup Terraform**: Installs Terraform 1.4.6
4. **Install Dependencies**: Installs project dependencies
5. **Install CDKTF**: Installs the Cloud Development Kit for Terraform CLI
6. **Configure AWS Credentials**: Sets up AWS authentication using GitHub Secrets
7. **Login to Amazon ECR**: Authenticates with ECR for Docker image operations
8. **Build and Push Docker Images**: Builds and pushes Docker images for:
   - Backend service
   - Prometheus monitoring
   - Grafana dashboards
9. **Run Backend Tests**: Runs the test suite for the backend
10. **Prepare Lambda Function**: Builds the data import Lambda function
11. **Prepare Import Script**: Sets up the data import script
12. **Import Existing Resources**: Imports existing AWS resources into CDKTF state
13. **Deploy Infrastructure**: Deploys the infrastructure using CDKTF
14. **Verify Deployment**: Validates that key resources (ALB, ECS services, RDS) are running correctly
15. **Trigger Resource Check**: Automatically triggers the resource check workflow

### Health Monitoring (`health-monitor.yml`)

This workflow runs hourly health checks on the deployed infrastructure and creates GitHub issues when problems are detected.

#### Workflow Steps:

1. **Checkout Code**: Retrieves the latest code from the repository
2. **Configure AWS Credentials**: Sets up AWS authentication using GitHub Secrets
3. **Install Dependencies**: Installs required dependencies and tools
4. **Run Health Check**: Checks the health of:
   - Application Load Balancer (`prod-e-alb`)
   - Backend service health endpoint
   - Prometheus monitoring endpoint
   - Grafana dashboard endpoint
   - ECS services status
   - RDS database status
5. **Upload Health Results**: Saves health check data as workflow artifacts
6. **Create GitHub Issue**: Creates an issue if any service is unhealthy
7. **Notify on Slack**: Sends Slack notification for unhealthy services (if Slack webhook is configured)

### Resource Check (`resource-check.yml`)

This workflow audits AWS resources after deployment to ensure proper configuration and avoid resource sprawl.

#### Workflow Steps:

1. **Checkout Code**: Retrieves the latest code from the repository
2. **Configure AWS Credentials**: Sets up AWS authentication using GitHub Secrets
3. **Install Tools**: Installs jq for JSON processing
4. **Wait for Resources**: Ensures deployment is complete before checking
5. **Run Resource Check**: Executes the resource check script
6. **Generate CSV Report**: Creates a CSV file of resource details (optional)
7. **Upload Results**: Saves check results as workflow artifacts
8. **Notify on Slack**: Sends notification of resource check completion (if configured)

### Cleanup (`cleanup.yml`)

This workflow performs regular cleanup of unused AWS resources to manage costs and maintain system health.

#### Workflow Steps:

1. **Checkout Code**: Retrieves the latest code from the repository
2. **Configure AWS Credentials**: Sets up AWS authentication using GitHub Secrets
3. **Install Dependencies**: Installs required tools
4. **Run Pre-Cleanup Resource Check**: Documents resources before cleanup
5. **Run Cleanup Script**: Performs cleanup operations with specified parameters
6. **Run Post-Cleanup Resource Check**: Documents resources after cleanup
7. **Generate Summary**: Creates a report of changes made
8. **Upload Results**: Saves cleanup results as workflow artifacts
9. **Notify on Slack**: Sends notification of cleanup completion (if configured)

## Infrastructure Components

The workflows interact with the following key infrastructure components:

- **Application Load Balancer**: `prod-e-alb` - Routes traffic to services
- **ECS Cluster**: `prod-e-cluster` - Hosts containerized services
- **ECS Services**:
  - `backend-service` - Node.js API backend
  - `grafana-service` - Grafana dashboards for monitoring
  - `prometheus-service` - Prometheus metrics collection
- **RDS Database**: `prod-e-db` - PostgreSQL database
- **ECR Repositories**:
  - `prod-e-backend` - Backend container images
  - `prod-e-prometheus` - Prometheus container images
  - `prod-e-grafana` - Grafana container images

## Required Secrets

The workflows require the following secrets to be configured in the GitHub repository:

- `AWS_ACCESS_KEY_ID`: AWS IAM user access key with appropriate permissions
- `AWS_SECRET_ACCESS_KEY`: Corresponding secret key for the AWS IAM user
- `SLACK_WEBHOOK_URL`: (Optional) URL for Slack notifications

These credentials should have permissions for:

- ECR (pushing Docker images)
- ECS (updating services)
- CloudWatch (for logs)
- RDS (for database operations)
- ALB (for load balancer configuration)
- All other AWS services managed by the CDKTF code

## Setting Up Secrets

To set up the required secrets:

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Add the secrets with the names mentioned above

## Security Considerations

- The IAM user for CI/CD should have only the permissions necessary for deployment
- Consider using OpenID Connect (OIDC) instead of long-lived credentials for improved security
- Regularly rotate the AWS credentials used in the workflow
