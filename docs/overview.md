# Infrastructure Documentation Overview

## Introduction

This document serves as the main index for all infrastructure documentation in this project. The project uses Cloud Development Kit for Terraform (CDKTF) with TypeScript to define and deploy AWS infrastructure components.

## Available Documentation

| Component                 | Description                                                          | Document Link                            |
| ------------------------- | -------------------------------------------------------------------- | ---------------------------------------- |
| VPC and Networking        | Documentation about VPC, subnets, Internet Gateway, and routing      | [vpc-networking.md](./vpc-networking.md) |
| Application Load Balancer | Documentation about ALB, target groups, and listeners                | [load-balancer.md](./load-balancer.md)   |
| RDS PostgreSQL Database   | Documentation about RDS instance, security groups, and subnet groups | [rds-database.md](./rds-database.md)     |

## Infrastructure Overview

The current infrastructure consists of:

1. **Base Network Layer**

   - VPC with public and private subnets
   - Internet Gateway for public internet access
   - Route tables and associations

2. **Application Delivery Layer**

   - Application Load Balancer (ALB)
   - Target groups for future service integration
   - Security groups for controlling traffic

3. **Data Storage Layer**
   - PostgreSQL RDS instance
   - Database subnet groups
   - Security groups for database access

## Deployment Instructions

To deploy this infrastructure:

1. Ensure you have the necessary prerequisites:

   - Node.js (v18+)
   - Terraform CLI
   - CDKTF CLI
   - AWS CLI configured with appropriate credentials

2. Install dependencies:

   ```bash
   npm install
   cdktf get
   ```

3. Synthesize Terraform configuration:

   ```bash
   npm run synth
   ```

4. Deploy the infrastructure:

   ```bash
   npm run deploy
   ```

5. To destroy the infrastructure when no longer needed:
   ```bash
   npm run destroy
   ```

## Environment Configuration

The infrastructure is designed with configuration parameters that can be adjusted in the `config` object in `main.ts`. Key configuration parameters include:

- AWS region: us-west-2
- VPC CIDR: 10.0.0.0/16
- Public subnet CIDR: 10.0.1.0/24
- Private subnet CIDR: 10.0.2.0/24
- Database settings: instance class, engine version, credentials, etc.

## Future Plans

The infrastructure is designed to be expanded in the future. Planned enhancements include:

- Multi-AZ deployment for high availability
- ECS Fargate services for containerized applications
- CloudFront for content delivery
- S3 buckets for static content and file storage
- CloudWatch for monitoring and alarming
