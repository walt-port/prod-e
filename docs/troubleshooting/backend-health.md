# Backend Service Health Issues

## Common Issues

### Missing Health Check Dependencies

**Issue**: The backend container fails health checks because it's missing required utilities (e.g., `curl`, `wget`).

**Symptoms**:

- ECS tasks continually restart and fail health checks
- Task status shows as UNHEALTHY
- Service fails to stabilize
- Error messages in task logs may indicate failed health checks

**Resolution**:

1. Check the Dockerfile to ensure it includes necessary health check utilities
2. Update the Dockerfile to include the required packages:
   ```dockerfile
   # Install health check dependencies and security updates
   RUN apt-get update && \
       apt-get install -y --no-install-recommends \
       curl \
       ca-certificates \
       wget \
       && apt-get clean \
       && rm -rf /var/lib/apt/lists/*
   ```
3. Build and push a new image to ECR
4. Update the task definition to use the new image
5. Force a new deployment

### Incorrect Health Check Configuration

**Issue**: Health check command uses utilities not available in the container or incorrect endpoint paths.

**Symptoms**:

- Task health fluctuates between HEALTHY and UNHEALTHY
- Health check logs show command not found errors

**Resolution**:

1. Update the task definition to use a health check command compatible with the container
2. For containers with curl:
   ```json
   "healthCheck": {
       "command": [
           "CMD-SHELL",
           "curl -f http://localhost:3000/health || exit 1"
       ],
       "interval": 30,
       "timeout": 5,
       "retries": 3,
       "startPeriod": 60
   }
   ```
3. For containers without curl, use wget:
   ```json
   "healthCheck": {
       "command": [
           "CMD-SHELL",
           "wget -q --spider http://localhost:3000/health || exit 1"
       ],
       "interval": 30,
       "timeout": 5,
       "retries": 3,
       "startPeriod": 60
   }
   ```

## Monitoring Tools

The following monitoring tools can help diagnose backend health issues:

1. **monitor-health.sh** - Checks the health status of all services
2. **resource_check.sh** - Provides detailed information about AWS resources

## Recent Fixes

### March 2025 Health Check Fix

Fixed issues with backend health checks by:

1. Updated the backend Dockerfile to include curl and other necessary utilities
2. Updated the task definition to use curl for health checks
3. Fixed the resource_check.sh script to use bash arithmetic instead of bc
4. Updated the monitor-health.sh script to properly check endpoint health via the ALB

These changes ensure that the backend service maintains proper health status and can be effectively monitored.
