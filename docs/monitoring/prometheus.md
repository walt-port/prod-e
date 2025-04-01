# Prometheus Configuration

## Overview

Prometheus is deployed as an ECS Fargate task in the `prod-e-cluster`. It is configured to scrape metrics from the backend service and provides a powerful query language for analyzing time-series data.

## Architecture

- **ECS Fargate Task**: Prometheus runs as a containerized service in ECS Fargate.
- **Health Check**: The task includes a health check that verifies the Prometheus server is running correctly.
- **Load Balancer Integration**: Prometheus is accessible via the Application Load Balancer (`prod-e-alb`) at the `/prometheus` path.

## Configuration

### Task Definition

The Prometheus task definition includes:

- Container image: `043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-prometheus:latest`
- Port mapping: 9090
- Health check: `wget -q -O - http://localhost:9090/-/healthy || exit 1` <!-- TODO: Verify health check command (wget vs nc?) -->
- Command: `--web.external-url=/prometheus` (configures Prometheus to use the /prometheus path prefix)
- CPU: 256 units <!-- TODO: Verify CPU/Memory values -->
- Memory: 512 MB <!-- TODO: Verify CPU/Memory values -->

### Load Balancer Configuration

Prometheus is accessible through the Application Load Balancer with the following configuration:

- Target Group: `prometheus-tg`
- Path Pattern: `/prometheus` and `/prometheus/*`
- Health Check Path: `/-/healthy`
- Port: 9090

## Access Information

Prometheus can be accessed at:

```
http://prod-e-alb-962304124.us-west-2.elb.amazonaws.com/prometheus/
```

## Testing and Validation

To verify Prometheus is working correctly:

1. Check the health of the Prometheus service:

   ```
   aws ecs describe-tasks --cluster prod-e-cluster --tasks $(aws ecs list-tasks --cluster prod-e-cluster --family prom-task --query 'taskArns[0]' --output text --region us-west-2) --region us-west-2 | grep healthStatus
   ```

2. Verify the Prometheus endpoint is accessible:

   ```
   curl -I http://prod-e-alb-962304124.us-west-2.elb.amazonaws.com/prometheus/
   ```

3. Check that metrics are being collected:
   ```
   curl http://prod-e-alb-962304124.us-west-2.elb.amazonaws.com/prometheus/api/v1/targets
   ```

## Troubleshooting

Common issues and their resolutions:

1. **Prometheus Task Unhealthy**:

   - Check the task health status using `aws ecs describe-tasks`
   - Verify the container logs in CloudWatch
   - Ensure the health check endpoint is accessible within the container

2. **Prometheus Endpoint Inaccessible**:

   - The Prometheus UI is accessible via the ALB at `/prometheus/`
   - The health check endpoint is at `/prometheus/-/healthy`
   - Verify the ALB listener rules are correctly configured for the `/prometheus` path pattern
   - Ensure the target group has a healthy target

3. **Web External URL Configuration**:
   - Prometheus is configured with `--web.external-url=/prometheus` to handle path-based routing
   - This configuration ensures that all internal links and API endpoints use the correct path prefix
   - If changing this configuration, update the ALB listener rules accordingly

## Future Enhancements

1. **Alerting**: Implement AlertManager for notification capabilities
2. **Persistent Storage**: Add EFS for long-term storage of metrics
3. **High Availability**: Configure multiple Prometheus instances for redundancy
4. **Federation**: Set up federation for scaling the monitoring solution

## Related Documentation

- [Grafana Documentation](./grafana.md) - Information about the Grafana visualization platform
- [Monitoring Overview](./monitoring.md) - General monitoring architecture and strategy

---

**Last Updated**: [Current Date - will be filled by system]
**Version**: 1.1
