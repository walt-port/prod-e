# GitHub Actions CI/CD

This directory contains GitHub Actions workflow configurations for continuous integration and deployment of the Production Experience Showcase (prod-e) project.

## Workflows

### Deploy (`deploy.yml`)

This workflow automates the build, test, and deployment process whenever changes are pushed to the `main` branch.

#### Workflow Steps:

1. **Checkout Code**: Retrieves the latest code from the repository
2. **Setup Node.js**: Installs Node.js 16.x
3. **Install CDKTF**: Installs the Cloud Development Kit for Terraform CLI
4. **Install Dependencies**: Installs project dependencies
5. **Generate CDKTF Providers**: Generates provider bindings
6. **Configure AWS Credentials**: Sets up AWS authentication using GitHub Secrets
7. **Build and Push Backend**: Builds and pushes the backend Docker image to ECR
8. **Build and Push Prometheus**: Builds and pushes the Prometheus Docker image to ECR
9. **Run Backend Tests**: Runs the test suite for the backend
10. **Deploy Infrastructure**: Synthesizes and deploys the infrastructure using CDKTF

## Required Secrets

The workflow requires the following secrets to be configured in the GitHub repository:

- `AWS_ACCESS_KEY_ID`: AWS IAM user access key with appropriate permissions
- `AWS_SECRET_ACCESS_KEY`: Corresponding secret key for the AWS IAM user

These credentials should have permissions for:

- ECR (pushing Docker images)
- ECS (updating services)
- CloudWatch (for logs)
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
