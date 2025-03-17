# Container Deployment Process

## Overview

This document describes the process for building, pushing, and deploying Docker container images to AWS Elastic Container Registry (ECR) and Amazon ECS Fargate.

## Architecture

The container architecture consists of:

- An ECR repository to store container images
- A multi-stage Dockerfile optimized for security and minimal size
- An ECS Fargate service that pulls and runs the images
- Integration with the RDS database and Application Load Balancer

## Components

### ECR Repository

The Amazon Elastic Container Registry (ECR) is a fully managed container registry:

- Repository Name: prod-e-backend
- Image Scanning: Enabled (scanOnPush: true)
- Image Tag Mutability: MUTABLE (allows overwriting of tags)

### Dockerfile

The backend application uses a multi-stage Dockerfile for optimal security and efficiency:

- Base Image: Node.js 16
- Stages:
  1. Builder stage - installs all dependencies and builds the application
  2. Production stage - includes only production dependencies
- Security features:
  - Runs as a non-root user (nodeuser)
  - Includes container health checks
  - Uses a minimal slim image for production

### Build and Push Process

The build and push process is automated through a shell script:

```bash
./scripts/deployment/build-and-push.sh backend
```

This script:

1. Builds the Docker image from the backend directory
2. Authenticates with AWS ECR
3. Tags the image appropriately
4. Pushes the image to the ECR repository

### ECS Task Definition

The ECS task definition is configured to use the ECR image:

- Image: `${ecrRepository.repositoryUrl}:latest`
- CPU/Memory: 0.25 vCPU (256 units) / 0.5GB (512MB)
- Port Mapping: Container port 3000 → Host port 3000
- Environment Variables:
  - Database connection details
  - NODE_ENV=production
- Health Check: HTTP request to /health endpoint
- Logs: CloudWatch Logs

## Deployment Process

### Initial Deployment

1. Build and push the Docker image:

   ```bash
   ./scripts/deployment/build-and-push.sh backend
   ```

2. Deploy the updated infrastructure:
   ```bash
   npm run deploy
   ```

### Updating the Application

When making changes to the backend application:

1. Implement and test changes locally
2. Rebuild and push the Docker image:

   ```bash
   ./scripts/deployment/build-and-push.sh backend
   ```

3. The ECS service will automatically detect the new image tagged with "latest" and update its tasks

## Continuous Integration/Deployment (Future)

Future enhancements planned for the CI/CD pipeline:

1. GitHub Actions workflow to automatically:

   - Build and test the application
   - Build and push the Docker image
   - Deploy infrastructure changes when merging to main

2. Version tagging for container images:
   - Git commit hash tags
   - Semantic versioning (v1.0.0, v1.1.0, etc.)
   - Better control over rollbacks

## Troubleshooting

Common issues and resolutions:

### Container Fails to Start

1. Check the CloudWatch logs:

   ```bash
   aws logs get-log-events --log-group-name /ecs/prod-e-task --log-stream-name <stream-name>
   ```

2. Verify the container health check is passing:
   ```bash
   aws ecs describe-tasks --cluster prod-e-cluster --tasks <task-id>
   ```

### ECR Access Issues

1. Verify the ECS task execution role has appropriate permissions
2. Check ECR repository policies
3. Ensure ECR repository exists in the same region as the ECS service

## Best Practices

1. Tag images with specific versions for production (not just "latest")
2. Implement automated testing in the CI/CD pipeline
3. Keep images small and secure by:
   - Using multi-stage builds
   - Including only necessary files
   - Running as non-root users
   - Regular security scanning
