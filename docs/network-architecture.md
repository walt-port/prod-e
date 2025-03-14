# Network Architecture Documentation

## Overview

The prod-e infrastructure follows AWS best practices for secure, scalable, and highly available network architecture. This document details the network components, configuration, and design considerations implemented in the project.

## VPC Configuration

The Virtual Private Cloud (VPC) serves as the network foundation for all AWS resources and is configured with the following specifications:

- **CIDR Block**: 10.0.0.0/16
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled
- **Region**: us-west-2
- **Proper Tagging**: All resources tagged for management

## Multi-AZ Subnet Layout

The infrastructure is deployed across multiple availability zones (us-west-2a and us-west-2b) for improved reliability and to meet AWS requirements.

### Public Subnets

Public subnets host resources that need direct internet access, such as the NAT Gateway and Application Load Balancer.

| Subnet          | CIDR Block  | Availability Zone | Purpose          |
| --------------- | ----------- | ----------------- | ---------------- |
| public-subnet-a | 10.0.1.0/24 | us-west-2a        | ALB, NAT Gateway |
| public-subnet-b | 10.0.3.0/24 | us-west-2b        | ALB redundancy   |

### Private Subnets

Private subnets host internal resources that don't need direct internet access but may need outbound internet access via the NAT Gateway.

| Subnet           | CIDR Block  | Availability Zone | Purpose                   |
| ---------------- | ----------- | ----------------- | ------------------------- |
| private-subnet-a | 10.0.2.0/24 | us-west-2a        | ECS Tasks, RDS            |
| private-subnet-b | 10.0.4.0/24 | us-west-2b        | ECS Tasks, RDS redundancy |

## Internet Access Components

### Internet Gateway

An Internet Gateway provides direct internet access for resources in public subnets. It allows:

- Outbound internet access for resources in public subnets
- Inbound access to public resources from the internet (e.g., to the ALB)

### NAT Gateway

A Network Address Translation (NAT) Gateway enables resources in private subnets to access the internet while preventing direct inbound access from the internet.

#### Configuration

- **Location**: Deployed in public-subnet-a (us-west-2a)
- **EIP**: Associated with an Elastic IP for consistent outbound addressing
- **Route Association**: Private subnet route tables include a route to the NAT Gateway for internet traffic (0.0.0.0/0)

#### Purpose

The NAT Gateway serves several critical functions:

1. **Container Image Pulls**: Allows ECS tasks in private subnets to pull Docker images from ECR
2. **Software Updates**: Enables package updates within containers
3. **API Calls**: Facilitates outbound API calls to external services
4. **Dependency Downloads**: Permits downloading dependencies during container startup

## Route Tables

### Public Route Table

The public route table includes:

- Local VPC traffic (10.0.0.0/16) → local
- Internet traffic (0.0.0.0/0) → Internet Gateway

### Private Route Table

The private route table includes:

- Local VPC traffic (10.0.0.0/16) → local
- Internet traffic (0.0.0.0/0) → NAT Gateway

## Security Groups

### Application Load Balancer Security Group

- **Inbound**: HTTP (80) and HTTPS (443) from internet
- **Outbound**: All traffic to VPC CIDR

### ECS Task Security Group

- **Inbound**: Traffic from ALB Security Group on application port (3000)
- **Outbound**: All traffic to internet (via NAT Gateway)

### RDS Security Group

- **Inbound**: PostgreSQL (5432) from ECS Task Security Group
- **Outbound**: No outbound rules (not needed)

## Implementation Status

The following network components have been successfully implemented:

- ✅ VPC with DNS support and hostnames
- ✅ Public and private subnets across two availability zones
- ✅ Internet Gateway for public subnet internet access
- ✅ NAT Gateway for private subnet outbound internet access
- ✅ Route tables and associations for proper traffic routing
- ✅ Security groups for access control

## Network Troubleshooting

### Common Issues

#### ECS Tasks Cannot Pull Images

**Symptoms**:

- Tasks fail to start with "CannotPullContainerError"
- Error messages reference ECR authentication or connection issues

**Resolution**:

1. Verify NAT Gateway is deployed in public subnet
2. Check private subnet route table has route to NAT Gateway
3. Ensure the ECS Task Security Group allows outbound traffic
4. Validate ECS Task Execution Role has permissions for ECR

#### Health Checks Failing

**Symptoms**:

- Tasks start but fail health checks
- ALB doesn't route traffic to backend

**Resolution**:

1. Ensure health check endpoint is properly implemented in the application
2. Verify security groups allow traffic between ALB and ECS tasks
3. Check that health check path in target group matches the application endpoint (/health)
4. Verify health check command is compatible with container environment (Node.js)

## Maintenance Considerations

### Cost Optimization

- **NAT Gateway**: Costs approximately $0.045 per hour (~$32/month) plus data processing fees
- **Data Transfer**: Evaluate outbound data transfer to optimize costs

### High Availability

The current implementation provides basic multi-AZ redundancy for networking components. For enhanced high availability in production environments, consider:

- Deploying a NAT Gateway in each availability zone for redundancy
- Creating custom network ACLs for additional security layers
- Implementing AWS Transit Gateway for more complex network architectures

## Lessons Learned

During implementation, we encountered several important AWS requirements:

1. **Application Load Balancer**:

   - ALBs must have subnets in at least two AZs
   - This requirement led to adding a second public subnet

2. **RDS Subnet Group**:
   - AWS requires DB subnet groups to span at least two AZs, even for single-AZ database deployments
   - This requirement necessitated adding a second private subnet

## Improvement History

| Date       | Change                                         | Reason                                                            |
| ---------- | ---------------------------------------------- | ----------------------------------------------------------------- |
| 2025-03-14 | Added NAT Gateway to public-subnet-a           | Enable ECS tasks in private subnets to access ECR for image pulls |
| 2025-03-14 | Added public and private subnets in us-west-2b | Meet AWS requirements for ALB and RDS DB subnet groups            |
| 2025-03-14 | Updated ALB target group health check path     | Change from / to /health for accurate service health monitoring   |
