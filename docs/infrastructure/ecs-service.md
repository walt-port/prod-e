# ECS Fargate Service Documentation

## Overview

This document provides comprehensive information about the ECS Fargate service implementation for the Production Experience Showcase project. It covers the ECS cluster, task definition, service configuration, and health check implementation.

## ECS Fargate Architecture

Amazon Elastic Container Service (ECS) with the Fargate launch type provides a serverless compute engine for containers. Key components in our implementation include:

### ECS Cluster

A logical grouping of tasks or services.

- **Name**: prod-e-cluster
- **Capacity Providers**: FARGATE
- **Default Capacity Provider Strategy**: FARGATE with weight 1

### Task Definition

Defines how containers should run.

- **Family**: prod-e-task
- **CPU**: 256 (0.25 vCPU) <!-- TODO: Verify CPU/Memory values -->
- **Memory**: 512 MB <!-- TODO: Verify CPU/Memory values -->
- **Network Mode**: awsvpc
- **Task Execution Role**: ecs-task-execution-role
- **Task Role**: ecs-task-role

### Container Definition

Specifies configuration for the container.

- **Name**: prod-e-container
- **Image**: 043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:latest
- **Port Mappings**: 3000:3000
- **Essential**: Yes

## Health Check Configuration

### Container Health Check

The ECS task definition includes the following health check configuration:

```json
"healthCheck": {
  "command": ["CMD-SHELL", "node -e \"require('http').request({host: 'localhost', port: 3000, path: '/health', timeout: 2000}, (res) => { process.exit(res.statusCode !== 200 ? 1 : 0); }).on('error', () => process.exit(1)).end()\""],
  "interval": 30,
  "timeout": 5,
  "retries": 3,
  "startPeriod": 60
}
```

#### Key Components

- **Command**: Uses Node.js to make an HTTP request to the `/health` endpoint
- **Interval**: Checks run every 30 seconds
- **Timeout**: Each check times out after 5 seconds
- **Retries**: Allows 3 failed checks before marking the container as unhealthy
- **Start Period**: Gives the container 60 seconds to initialize before beginning health checks

### Target Group Health Check

The ALB target group is configured with the following health check settings:

```typescript
healthCheck: {
  enabled: true,
  path: '/health',
  port: 'traffic-port',
  healthyThreshold: 3,
  unhealthyThreshold: 3,
  timeout: 5,
  interval: 30,
  matcher: '200-299',
}
```

This configuration ensures the load balancer properly routes traffic to healthy ECS tasks.

### Health Check Endpoint

The application exposes a `/health` endpoint that returns status information:

```json
{
  "status": "ok",
  "timestamp": "2025-03-14T07:11:18.325Z",
  "database": "connected"
}
```

The endpoint performs the following validations:

1. Verifies the application is running
2. Checks database connectivity
3. Returns a 200 OK response if all systems are operational

## Previous Issues and Solutions

### Health Check Implementation

The health check was initially configured to use `curl`:

```json
"healthCheck": {
  "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
  "interval": 30,
  "timeout": 5,
  "retries": 3,
  "startPeriod": 60
}
```

This approach presented the following problems:

- The application container did not include `curl`, causing health checks to fail
- Image size increased when adding `curl` as a dependency
- Error handling was limited compared to the Node.js approach

### Solution: Node.js-based Health Checks

Using Node.js for health checks provides several advantages:

1. **Dependency Reduction**: Eliminates the need for additional packages like `curl`
2. **Improved Error Handling**: Can distinguish between different types of failures
3. **Performance**: Lighter weight than spawning a new process
4. **Consistency**: Uses the same runtime as the application

### Target Group Path Configuration

The ALB target group was initially configured with a health check path of `/`, which didn't properly validate application health. This was updated to use the `/health` endpoint for accurate health assessment.

## Service Configuration

### ECS Service

- **Name**: prod-e-service
- **Launch Type**: FARGATE
- **Platform Version**: LATEST
- **Desired Count**: 1
- **Health Check Grace Period**: 60 seconds

### Networking

- **VPC**: main-vpc
- **Subnets**: private-subnet-a (primary), private-subnet-b
- **Security Groups**: ecs-security-group (allowing inbound traffic from ALB on port 3000)
- **Public IP Assignment**: Disabled (using private IP only)

### Load Balancing

- **Target Group**: ecs-target-group-v2
- **Target Type**: ip
- **Container Name and Port**: prod-e-container:3000

## IAM Configuration

### Task Execution Role

Permissions for ECS to pull container images and publish logs:

- **Managed Policies**:
  - AmazonECR-ReadOnly
  - AmazonECSTaskExecutionRolePolicy
  - CloudWatchLogsFullAccess

### Task Role

Permissions for the application running in the container:

- **Custom Policies**:
  - Allow access to specific AWS services needed by the application
  - Allow CloudWatch metrics publishing

## Troubleshooting ECS Issues

### Common Issues and Resolutions

#### Image Pull Failures

**Symptoms**:

- Tasks fail to start with "CannotPullContainerError"

**Resolution**:

1. Verify the NAT Gateway is properly configured for private subnets
2. Check ECR repository permissions
3. Validate task execution role has ECR permissions

#### Health Check Failures

**Symptoms**:

- Tasks start but fail health checks
- ALB doesn't route traffic to backend

**Resolution**:

1. Verify the application is properly implementing the `/health` endpoint
2. Check security group rules allow traffic between ALB and ECS tasks
3. Ensure health check path in ALB target group matches application endpoint
4. Confirm container health check command is properly implemented

#### Container Crashes

**Symptoms**:

- Tasks repeatedly start and stop
- "STOPPED" status with exit code 1 or 137

**Resolution**:

1. Check container logs in CloudWatch
2. Verify container has sufficient memory/CPU resources
3. Check for application crashes in logs

## Monitoring and Logging

### CloudWatch Logs

All container logs are sent to CloudWatch Logs for monitoring and troubleshooting:

- **Log Group**: /ecs/prod-e-task
- **Log Stream**: prod-e-container/[task-id]

### CloudWatch Metrics

ECS publishes the following metrics to CloudWatch:

- CPU and memory utilization
- Task count (desired, running, pending)
- Service metrics (deployment status)

## Best Practices

1. **Right-size Resources**: Match CPU and memory to application needs
2. **Use Multiple Availability Zones**: Deploy across at least two AZs for high availability
3. **Implement Robust Health Checks**: Check critical components for accurate health assessment
4. **Enable Auto-scaling**: Use scaling policies based on CPU/memory utilization
5. **Optimize Container Images**: Use small, efficient images to reduce startup time

## Future Enhancements

<!-- TODO: Review/update this section based on current implementation -->

1. **Service Auto-scaling**: Implement auto-scaling based on CPU and memory metrics
2. **Multi-AZ Deployment**: Ensure tasks are distributed across multiple AZs
3. **Blue/Green Deployments**: Implement CodeDeploy for zero-downtime deployments
4. **Container Insights**: Enable ECS Container Insights for enhanced monitoring

## Deployment Instructions

To deploy or update the ECS service:

1. Build and push the container image to ECR
2. Update the task definition if container configuration has changed
3. Deploy the infrastructure using CDKTF
4. Verify the service is running with `aws ecs describe-services`

---

**Last Updated**: [Current Date - will be filled by system]
**Version**: 1.1
