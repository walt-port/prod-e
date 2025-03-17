# Deployment Guide

## Overview

This document provides detailed instructions for deploying the Production Experience Showcase project to AWS. It covers both manual deployment steps and automated CI/CD deployment options.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Deployment Architecture](#deployment-architecture)
- [Manual Deployment](#manual-deployment)
- [CI/CD Deployment](#cicd-deployment)
- [Deployment Verification](#deployment-verification)
- [Post-Deployment Configuration](#post-deployment-configuration)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)

## Prerequisites

Before deploying, ensure you have:

| Requirement       | Description                                     |
| ----------------- | ----------------------------------------------- |
| AWS Account       | Active AWS account with appropriate permissions |
| AWS CLI           | Configured with appropriate credentials         |
| Node.js           | Version 18 or higher                            |
| Terraform         | Version 1.5.0 or higher                         |
| CDK for Terraform | Installed via npm                               |
| ECR Repository    | Created for storing Docker images               |

### Required Permissions

The deployment requires the following AWS permissions:

- EC2: Create, describe, and manage EC2 resources
- VPC: Create and manage VPC, subnets, security groups
- ECS: Create and manage clusters, services, and task definitions
- RDS: Create and manage database instances
- IAM: Create and manage roles and policies
- S3: Access to Terraform state bucket
- DynamoDB: Access to state locking table
- Secrets Manager: Create and manage secrets

## Deployment Architecture

The deployment creates the following infrastructure components:

1. **Networking Layer**:

   - VPC with public and private subnets across multiple AZs
   - Internet Gateway, NAT Gateway, and route tables
   - Security groups for different components

2. **Compute Layer**:

   - ECS Fargate cluster
   - ECS services and task definitions
   - Application Load Balancer

3. **Storage Layer**:

   - RDS PostgreSQL database
   - EFS filesystem for Grafana persistence

4. **Monitoring Layer**:
   - Prometheus on ECS Fargate
   - Grafana on ECS Fargate

## Manual Deployment

### Step 1: Prepare Environment

1. Clone the repository:

   ```bash
   $ git clone https://github.com/your-username/prod-e.git
   $ cd prod-e
   ```

2. Install dependencies:

   ```bash
   $ npm install
   $ npx cdktf get
   ```

### Step 2: Build and Push Docker Images

1. Build the backend image:

   ```bash
   $ cd backend
   $ docker build -t prod-e-backend:latest .
   ```

2. Tag and push to ECR:

   ```bash
   $ aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
   $ docker tag prod-e-backend:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:latest
   $ docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:latest
   ```

### Step 3: Configure Deployment

1. Update environment variables in the configuration:

   ```typescript
   // infrastructure/main.ts
   const config = {
     // Update any necessary configuration parameters
     backendImage: '<account-id>.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:latest',
     environment: 'prod',
     // ...other configuration
   };
   ```

### Step 4: Deploy Infrastructure

1. Synthesize Terraform configuration:

   ```bash
   $ npm run synth
   ```

2. Deploy the infrastructure:

   ```bash
   $ npm run deploy
   ```

   This will prompt for confirmation before applying changes.

## CI/CD Deployment

The project includes a GitHub Actions workflow for automated deployment.

### GitHub Actions Workflow

The workflow is defined in `.github/workflows/deploy.yml` and performs the following steps:

1. Checkout code
2. Set up Node.js
3. Install dependencies
4. Build and test the project
5. Build Docker images
6. Push images to ECR
7. Deploy infrastructure using CDKTF

### Setting Up CI/CD

1. Configure GitHub repository secrets:

   - `AWS_ACCESS_KEY_ID`: AWS access key with deployment permissions
   - `AWS_SECRET_ACCESS_KEY`: Corresponding secret key
   - `AWS_REGION`: AWS region (us-west-2)
   - `ECR_REPOSITORY`: ECR repository name
   - `DB_PASSWORD`: Database password (for production)

2. Enable workflows in GitHub repository settings.

3. Push changes to the main branch to trigger deployment:

   ```bash
   $ git push origin main
   ```

## Deployment Verification

After deployment completes, verify that all components are functioning correctly:

### 1. Check Infrastructure Status

```bash
$ aws ecs list-services --cluster prod-e-cluster
$ aws rds describe-db-instances --db-instance-identifier postgres-instance
$ aws elbv2 describe-load-balancers --names prod-e-alb
```

### 2. Verify Application Health

1. Get the ALB DNS name:

   ```bash
   $ aws elbv2 describe-load-balancers --names prod-e-alb --query "LoadBalancers[0].DNSName" --output text
   ```

2. Check the health endpoint:

   ```bash
   $ curl -I http://<alb-dns-name>/health
   ```

   Expected response: HTTP 200 OK

### 3. Verify Monitoring

1. Access Prometheus:

   ```bash
   $ curl http://<alb-dns-name>/prometheus/-/ready
   ```

2. Access Grafana (if deployed):

   Open `http://<alb-dns-name>/grafana` in a web browser.

## Post-Deployment Configuration

### Grafana Setup

1. Log in with the admin credentials stored in Secrets Manager:

   ```bash
   $ aws secretsmanager get-secret-value --secret-id prod-e-grafana-admin
   ```

2. Configure Prometheus data source:
   - URL: `http://prometheus-service:9090`
   - Access: Server

### Database Initialization

If needed, run database migrations:

```bash
$ aws ecs run-task --cluster prod-e-cluster --task-definition prod-e-migration
```

## Rollback Procedures

### Rolling Back Infrastructure

To roll back to a previous infrastructure state:

1. Identify the target version in the S3 bucket:

   ```bash
   $ aws s3api list-object-versions --bucket prod-e-terraform-state --prefix terraform.tfstate
   ```

2. Restore that version:

   ```bash
   $ aws s3api get-object --bucket prod-e-terraform-state --key terraform.tfstate --version-id <version-id> terraform.tfstate.backup
   $ aws s3api put-object --bucket prod-e-terraform-state --key terraform.tfstate --body terraform.tfstate.backup
   ```

3. Apply the previous state:

   ```bash
   $ cd cdktf.out/stacks/prod-e
   $ terraform apply
   ```

### Rolling Back Container Images

To roll back to a previous container version:

1. Update the task definition to use the previous image tag:

   ```typescript
   const config = {
     backendImage: '<account-id>.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:previous-tag',
     // ...other configuration
   };
   ```

2. Deploy the updated configuration:

   ```bash
   $ npm run deploy
   ```

## Troubleshooting

### Common Deployment Issues

| Issue                        | Resolution                                           |
| ---------------------------- | ---------------------------------------------------- |
| State lock errors            | Release the lock manually in DynamoDB                |
| IAM permission errors        | Check IAM roles and policies for missing permissions |
| ECS service failing to start | Check CloudWatch logs for the service                |
| Database connection issues   | Verify security group rules and credentials          |

### Checking Logs

View ECS service logs:

```bash
$ aws logs get-log-events --log-group-name /ecs/prod-e-backend --log-stream-name <log-stream>
```

View RDS logs:

```bash
$ aws rds download-db-log-file-portion --db-instance-identifier postgres-instance --log-file-name postgres.log
```

## Related Documentation

- [Infrastructure Overview](./overview.md)
- [Remote State Management](./remote-state.md)
- [CI/CD Pipeline](./ci-cd.md)
- [Monitoring Setup](./monitoring.md)

---

**Last Updated**: 2025-03-15
**Version**: 1.0
