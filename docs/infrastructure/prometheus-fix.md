# Prometheus Service Fix

## Issue Overview

The Prometheus service was deployed with several issues that prevented it from functioning correctly:

1. **Missing Health Check**: The container didn't have a health check configured, making it difficult for ECS to determine if the service was healthy.
2. **No Path Prefix Configuration**: Prometheus wasn't configured with the proper path prefix for ALB routing (`/prometheus`).
3. **No Load Balancer Registration**: The service wasn't registered with the Application Load Balancer target group, making it inaccessible from the outside.
4. **Basic Docker Image**: The Docker image lacked the proper command-line arguments and health check configuration.

## Solution Implemented

### 1. Improved Docker Image

We created an improved Docker image for Prometheus with:

- Built-in container health check
- Proper command-line arguments to support path-based routing
- Configuration for external URL

```Dockerfile
# Base image for Prometheus
FROM prom/prometheus:latest

# Copy Prometheus configuration
COPY prometheus.yml /etc/prometheus/

# Expose port
EXPOSE 9090

# Add health check using the built-in health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD [ -x "$(command -v wget)" ] && wget -q -O- http://localhost:9090/-/healthy || exit 1

# Set command with proper path prefix configuration
CMD [ "/bin/prometheus", \
    "--config.file=/etc/prometheus/prometheus.yml", \
    "--web.external-url=/prometheus", \
    "--web.route-prefix=/" ]
```

### 2. Improved Prometheus Configuration

We enhanced the Prometheus configuration to include:

- Global scrape settings
- Multiple job configurations
- Self-monitoring

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prod-e-backend'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['application-load-balancer-98932456.us-west-2.elb.amazonaws.com:3000'] # ALB DNS for backend service

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090'] # Self-monitoring
```

### 3. Service Configuration with Load Balancer

We registered the service with the load balancer by creating a new service configuration:

```json
{
  "cluster": "prod-e-cluster",
  "serviceName": "prod-e-prom-service",
  "taskDefinition": "prom-task:7",
  "desiredCount": 1,
  "launchType": "FARGATE",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [...],
      "securityGroups": [...],
      "assignPublicIp": "DISABLED"
    }
  },
  "loadBalancers": [
    {
      "targetGroupArn": "arn:aws:elasticloadbalancing:us-west-2:043309339649:targetgroup/prometheus-tg/2bfa005f80f6fc46",
      "containerName": "prometheus",
      "containerPort": 9090
    }
  ],
  "healthCheckGracePeriodSeconds": 120,
  "deploymentConfiguration": {
    "deploymentCircuitBreaker": {
      "enable": true,
      "rollback": true
    }
  }
}
```

## Implementation Steps

1. Built and pushed improved Prometheus Docker image:

   ```
   docker build -f Dockerfile.prometheus -t 043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-prometheus:latest .
   docker push 043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-prometheus:latest
   ```

2. Deleted the existing service to recreate it with load balancer configuration:

   ```
   aws ecs delete-service --cluster prod-e-cluster --service prod-e-prom-service --force
   ```

3. Created new service with load balancer configuration:
   ```
   aws ecs create-service --cli-input-json file://create-prometheus-service.json
   ```

## Results

The Prometheus service is now:

- Using a properly configured container image
- Running the Prometheus server with appropriate path prefix settings
- Registered with the load balancer
- Health-checked via the built-in Prometheus health endpoint

## Future Improvements

1. **Infrastructure as Code**: Update the infrastructure code (CDK) to include these configurations.
2. **Proper Alerting**: Add AlertManager for notification capabilities.
3. **Persistent Storage**: Add EFS for long-term storage of metrics.
4. **High Availability**: Consider configuring multiple Prometheus instances for redundancy.

## Related Documentation

- [Monitoring Overview](../monitoring/monitoring.md)
- [Grafana Documentation](../monitoring/grafana.md)
