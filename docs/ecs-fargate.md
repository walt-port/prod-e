# ECS Fargate Service

## Overview

This document describes the Amazon ECS Fargate infrastructure components created for the project.

## Architecture

The ECS architecture consists of:

- An ECS cluster for organizing container resources
- A Fargate task definition with a Node.js 16 container
- An ECS service that manages task instances
- Security groups allowing traffic from the ALB
- IAM roles for task execution permissions
- Integration with the Application Load Balancer

## Components

### ECS Cluster

The ECS cluster serves as a logical grouping for the containerized services:

- Name: prod-e-cluster
- Type: Standard ECS cluster

### Task Definition

The ECS task definition defines the container configuration:

- Family: prod-e-task
- Launch Type: FARGATE (serverless)
- Network Mode: awsvpc
- CPU: 256 (0.25 vCPU)
- Memory: 512 MB (0.5 GB)
- Container:
  - Name: dummy-container
  - Image: node:16 (base Node.js 16 image)
  - Port Mapping: Container port 80 -> Host port 80
  - Logging: CloudWatch logs with auto-creation

### IAM Roles

Two IAM roles are created for the ECS tasks:

1. **Task Execution Role**:

   - Allows ECS to pull container images and send logs
   - Uses the managed policy AmazonECSTaskExecutionRolePolicy

2. **Task Role**:
   - Allows the container to access AWS services
   - Currently minimal permissions (will be expanded as needed)

### Security Group

The ECS security group controls traffic to and from the ECS tasks:

- Inbound rules:
  - Allow HTTP (port 80) from the ALB security group only
- Outbound rules:
  - Allow all outbound traffic to anywhere (0.0.0.0/0)

### ECS Service

The ECS service manages task deployment and lifecycle:

- Name: prod-e-service
- Launch Type: FARGATE
- Strategy: REPLICA
- Desired Tasks: 1
- Network:
  - Subnet: Private subnet in us-west-2a
  - Security Group: ecs-security-group
  - Public IP Assignment: Disabled (accessed through ALB)
- Load Balancer Integration:
  - Target Group: ecs-target-group
  - Container: dummy-container
  - Port: 80

### Load Balancer Integration

The Application Load Balancer is configured to route traffic to the ECS service:

- A listener rule forwards all traffic (/\*) to the ECS target group
- Health checks ensure traffic is only routed to healthy tasks

## Resource Management

### Deployment

The ECS resources are deployed as part of the overall infrastructure using:

```bash
npm run deploy
```

### Teardown

There are two methods for cleaning up ECS resources:

1. **Using CDKTF (Recommended for Normal Use)**:

   ```bash
   npm run destroy
   ```

2. **Using the Python Teardown Script (For More Control)**:

   ```bash
   python scripts/teardown.py
   ```

   The teardown script provides detailed visibility into the resources being deleted and includes a confirmation step before proceeding with the deletion. For more information, see the [scripts README](../scripts/README.md).

## Future Enhancements

Planned enhancements for the ECS service include:

- Developing a proper Node.js/Express application to run in the container
- Setting up auto-scaling based on CPU/memory utilization
- Implementing a proper CI/CD pipeline for container updates
- Adding more sophisticated health checks
- Enhancing security with tighter IAM permissions
- Deploying across multiple availability zones for high availability
