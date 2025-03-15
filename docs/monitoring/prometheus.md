# Prometheus Configuration

## Overview

Prometheus is deployed as an ECS Fargate task in the `prod-e-cluster`. It is configured to scrape metrics from the backend service and provides a powerful query language for analyzing time-series data.

## Architecture

- **ECS Fargate Task**: Prometheus runs as a containerized service in ECS Fargate.
- **Health Check**: The task includes a health check that verifies the Prometheus server is running correctly.
- **Load Balancer Integration**: Prometheus is accessible via the Application Load Balancer at the `/prometheus` path.

## Configuration

### Task Definition

The Prometheus task definition includes:

- Container image: `043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-prometheus:latest`
- Port mapping: 9090
- Health check: `wget -q -O - http://localhost:9090/-/healthy || exit 1`
- CPU: 256 units
- Memory: 512 MB

### Load Balancer Configuration

Prometheus is accessible through the Application Load Balancer with the following configuration:

- Target Group: `prometheus-tg`
- Path Pattern: `/prometheus` and `/prometheus/*`
- Health Check Path: `/-/healthy`
- Port: 9090

## Access Information

Prometheus can be accessed at:

```
http://application-load-balancer-98932456.us-west-2.elb.amazonaws.com/prometheus/
```

## Testing and Validation

To verify Prometheus is working correctly:

1. Check the health of the Prometheus service:

   ```
   aws ecs describe-tasks --cluster prod-e-cluster --tasks $(aws ecs list-tasks --cluster prod-e-cluster --family prom-task --query 'taskArns[0]' --output text --region us-west-2) --region us-west-2 | grep healthStatus
   ```

2. Verify the Prometheus endpoint is accessible:

   ```
   curl -I http://application-load-balancer-98932456.us-west-2.elb.amazonaws.com/prometheus/
   ```

3. Check that metrics are being collected:
   ```
   curl http://application-load-balancer-98932456.us-west-2.elb.amazonaws.com/prometheus/api/v1/targets
   ```

## Troubleshooting

Common issues and their resolutions:

1. **Prometheus Task Unhealthy**:

   - Check the Prometheus logs: `aws logs get-log-events --log-group-name /ecs/prom-task --log-stream-name <log-stream-name> --region us-west-2`
   - Verify the health check endpoint is responding: `curl http://localhost:9090/-/healthy`

2. **Cannot Access Prometheus via ALB**:

   - Verify the target group is healthy: `aws elbv2 describe-target-health --target-group-arn <prometheus-target-group-arn> --region us-west-2`
   - Check the listener rule is correctly configured: `aws elbv2 describe-rules --listener-arn <listener-arn> --region us-west-2`

3. **No Metrics Showing**:
   - Verify the Prometheus configuration file includes the correct scrape targets
   - Check that the backend service is exposing metrics at the expected endpoint

## Future Enhancements

1. **Alerting**: Implement AlertManager for notification capabilities
2. **Persistent Storage**: Add EFS for long-term storage of metrics
3. **High Availability**: Configure multiple Prometheus instances for redundancy
4. **Federation**: Set up federation for scaling the monitoring solution

## Related Documentation

- [Grafana Documentation](./grafana.md) - Information about the Grafana visualization platform
- [Monitoring Overview](./monitoring.md) - General monitoring architecture and strategy
