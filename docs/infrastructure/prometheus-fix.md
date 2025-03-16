# Prometheus Service Fix

## Issues Identified

1. **Missing Health Check Configuration**: The Prometheus service was not configured with a proper health check, causing the ECS service to be unable to determine if the container was healthy.

2. **Path Prefix Configuration**: The Prometheus service was not configured with the correct path prefix for ALB routing.

3. **Load Balancer Registration**: The service was not properly registered with the Application Load Balancer target group.

4. **Basic Docker Image**: The Docker image was using the base image without proper command-line arguments and health check configuration.

5. **Configuration Path Issue**: The Prometheus configuration file was being copied to the wrong location in the container, causing the service to fail to start.

6. **Missing Dependencies**: The health check was failing because the container didn't have the necessary tools (wget/curl) to perform an HTTP check.

## Solutions Implemented

### Improved Docker Image

A new Docker image was created with:

- Proper health check using netcat (`nc`)
- Proper command-line arguments
- Configuration for external URL
- Correct configuration file path

```dockerfile
# Base image for Prometheus
FROM prom/prometheus:latest

# Copy Prometheus configuration to the correct location
COPY prometheus.yml /prometheus/

# Expose port
EXPOSE 9090

# Add simple health check by checking if the port is listening
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD nc -z localhost 9090 || exit 1

# Set command with proper path prefix configuration
CMD [ "/bin/prometheus", \
    "--config.file=/prometheus/prometheus.yml", \
    "--web.external-url=/prometheus", \
    "--web.route-prefix=/" ]
```

### Improved Prometheus Configuration

The Prometheus configuration was enhanced to include:

- Global scrape settings
- Multiple job configurations
- Self-monitoring

### Service Configuration with Load Balancer

A new service configuration was created to register the service with the load balancer:

- Cluster name: `prod-e-cluster`
- Service name: `prod-e-prom-service`
- Task definition: `prom-task`
- Desired count: `1`
- Launch type: `FARGATE`
- Network configuration with proper subnets and security groups
- Health check grace period: `120` seconds
- Load balancer configuration with target group, container name, and port

## Implementation Steps

1. Built and pushed the improved Prometheus Docker image:

   ```
   docker build -f Dockerfile.prometheus -t 043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-prometheus:latest .
   docker push 043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-prometheus:latest
   ```

2. Deleted the existing service:

   ```
   aws ecs delete-service --cluster prod-e-cluster --service prod-e-prom-service --force
   ```

3. Created a new service with load balancer configuration:

   ```
   aws ecs create-service --cli-input-json file://create-prometheus-service.json
   ```

4. Fixed the configuration path issue in the Dockerfile:

   - Changed the configuration path from `/etc/prometheus/` to `/prometheus/`
   - Updated the command to use the correct path: `--config.file=/prometheus/prometheus.yml`
   - Rebuilt and pushed the updated image
   - Created a new task definition revision
   - Updated the service to use the new task definition

5. Fixed the health check issue:
   - Updated the Dockerfile to use a simpler health check with `nc` (netcat)
   - Updated the task definition to use the same health check
   - Created a new task definition revision
   - Updated the service to use the latest task definition

## Results

- Prometheus service is now using a properly configured container image
- Service is running with appropriate path prefix settings
- Service is registered with the load balancer
- Service is health-checked using netcat to verify the port is open
- Configuration file is correctly located and loaded

## Future Improvements

1. **Infrastructure as Code**: Update Terraform or CloudFormation templates to include these changes for future deployments.

2. **Alerting**: Add AlertManager configuration for proper alerting.

3. **Persistent Storage**: Configure EFS for persistent storage of Prometheus data.

4. **High Availability**: Consider running multiple Prometheus instances for high availability.

## Related Documentation

- [Monitoring Overview](../monitoring.md)
- [Grafana Documentation](../grafana.md)
