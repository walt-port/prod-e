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

# Prometheus Service Fix Documentation

## Overview

This document outlines the issues and fixes implemented for the Prometheus monitoring system in the prod-e environment. The fixes address connection issues between Grafana and Prometheus, target health issues, and cleanup of unused security groups.

## Issues Addressed

1. **Grafana to Prometheus Connection (HTTP 404)**

   - Grafana was unable to access Prometheus metrics through its proxy, resulting in HTTP 404 errors
   - The Grafana datasource configuration was incorrectly pointing to an external URL

2. **Unhealthy Target in Prometheus Target Group**

   - One of the targets in the Prometheus target group was reporting as unhealthy with timeout errors

3. **Unused Security Groups**
   - Four security groups were identified as potentially unused, requiring verification and cleanup

## Solutions Implemented

### 1. Grafana Datasource Configuration Fix

The Grafana datasource configuration was updated to use the internal ECS service name for Prometheus:

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prod-e-prom-service:9090
    isDefault: true
    editable: false
```

This change allows Grafana to directly communicate with the Prometheus service within the ECS cluster using the service discovery mechanism provided by AWS ECS.

Implementation steps:

1. Modified the `datasources.yml` file in the Grafana provisioning configuration
2. Rebuilt and pushed the Grafana Docker image to ECR
3. Forced a new deployment of the Grafana service to use the updated configuration

### 2. Security Group Cleanup

Three unused security groups were identified and safely deleted:

- `prom-security-group (sg-0017d666e5148acac)`
- `ecs-security-group (sg-0a70331071c677329)`
- `db-security-group (sg-095f444f62444fc95)`

One security group, `efs-mount-security-group (sg-0be700337c9fb39cf)`, was found to be in use by an EFS mount target and was preserved.

A script (`scripts/cleanup-security-groups.sh`) was created to safely check and delete security groups, ensuring that:

- Groups are not associated with any network interfaces
- Groups are not referenced by rules in other security groups

## Monitoring and Validation

To validate the fixes:

1. **Grafana-Prometheus Connection**: Verify that Grafana dashboards can now display Prometheus metrics without 404 errors
2. **Target Health**: Monitor the health of Prometheus targets to determine if the unhealthy target recovers or requires further attention
3. **Security Group Status**: Confirm that the deleted security groups were not essential for any running services

## Next Steps

1. **Monitoring Health Check Improvement**: Review and potentially adjust the health check settings for the Prometheus target group to address the remaining unhealthy target
2. **Documentation Updates**: Update all relevant documentation to reflect the new architecture and configuration
3. **Infrastructure as Code**: Consider incorporating these changes into the infrastructure as code (Terraform/CloudFormation) to ensure persistence across deployments

## Progress Update (2025-03-16)

### Completed Tasks

1. ✅ Updated Grafana datasource configuration to use internal ECS service name
2. ✅ Rebuilt and pushed Grafana Docker image with updated configuration
3. ✅ Forced new deployment of Grafana service
4. ✅ Cleaned up unused security groups
5. ✅ Updated ALB health check settings for Prometheus target group
6. ✅ Updated documentation inventory

### Remaining Issues

1. ❌ One Prometheus target (10.0.4.217) still shows as unhealthy with timeout errors
2. ❌ Direct access to Prometheus API through ALB still returns 404 errors
3. ❌ Grafana proxy to Prometheus not returning data

### Next Actions

1. Investigate Prometheus container configuration to ensure it's properly handling requests at the correct path
2. Consider rebuilding the Prometheus container with updated configuration
3. Review network connectivity between Grafana and Prometheus services
4. Implement additional monitoring to track the health of the services
