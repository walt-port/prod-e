# Infrastructure Architecture

## Overview

The infrastructure for this project is built using the Cloud Development Kit for Terraform (CDKTF). It has been designed with modularity and separation of concerns in mind, allowing for easier maintenance and future expansion.

## Components

The infrastructure is divided into the following components:

### 1. Networking (`networking.ts`)

This module handles all network-related resources:

- VPC with DNS support
- Public and private subnets across multiple Availability Zones
- Internet Gateway for public internet access
- NAT Gateway for private subnet internet access
- Route tables and associations

### 2. Application Load Balancer (`alb.ts`)

This module manages the load balancing tier:

- Application Load Balancer in public subnets
- HTTP listener with rules
- Default fixed response for health checks

### 3. ECS Fargate (`ecs.ts`)

This module handles container orchestration:

- ECS Cluster
- Fargate service for the application
- Task definitions and container configurations

### 4. RDS Database (`rds.ts`)

This module manages the database tier:

- PostgreSQL RDS instance
- Database subnet group in private subnets
- Configuration for database parameters

### 5. Monitoring (`monitoring.ts`)

This module sets up observability:

- Prometheus service for metrics collection
- Integration with ECS and ALB

### 6. Backup (`backup.ts`)

This module handles data protection:

- S3 bucket for backups
- Lambda function for scheduled backups

## Main Stack

The `main.ts` file ties all these components together, creating a cohesive infrastructure stack with:

- Proper dependency management between components
- Output values for important resource attributes

## Deployment

The infrastructure can be deployed using standard CDKTF commands:

```bash
# Synthesize Terraform configuration
cdktf synth

# Deploy the infrastructure
cdktf deploy
```

## Security Considerations

- Network segregation with public/private subnets
- Security groups with least privilege access
- RDS in private subnets with controlled access

## Future Improvements

- Add more granular IAM permissions
- Implement auto-scaling for ECS services
- Add CloudWatch alarms for monitoring
- Enhance backup and disaster recovery capabilities
