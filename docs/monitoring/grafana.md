# Grafana Implementation

## Overview

Grafana has been implemented to visualize metrics collected by Prometheus. This document outlines the implementation details, including architecture decisions, configuration, and usage instructions.

## Architecture

### Components

1. **ECS Fargate Task**:

   - Single-AZ deployment for cost efficiency (~$15/month)
   - 0.25 vCPU and 0.5GB RAM allocation
   - Official Grafana OSS container image (version 10.0.0)

2. **Persistent Storage**:

   - EFS volume mounted at `/var/lib/grafana`
   - EFS access point with UID/GID 472 (Grafana user)
   - Lifecycle policy to transition to Infrequent Access after 30 days for cost optimization

3. **Access Control**:

   - Security groups limiting access to ALB only
   - Path-based routing via ALB at `/grafana`
   - Admin credentials stored in AWS Secrets Manager

4. **Backup System**:
   - Daily backups to S3 using Lambda function
   - Bucket with versioning enabled for backup history

## Configuration

### Dashboards

Pre-configured dashboards have been provisioned for:

- Node.js application metrics (event loop lag, memory usage, GC statistics)
- HTTP request metrics (counts, error rates, durations)
- System resources (CPU, memory)

The dashboards are stored in the EFS volume and are also backed up daily to S3.

### Data Sources

Grafana is configured with Prometheus as the default data source, connecting to the Prometheus server via the ALB.

### Alerting

Basic alerting has been configured for:

- High event loop lag (> 0.1s for 5 minutes)
- High error rate
- Notification channels set up for email alerts

## Access Information

- **URL**: http://{ALB_DNS}/grafana
- **Default username**: admin
- **Default password**: Stored in AWS Secrets Manager (grafana-admin-credentials)

## Testing and Validation

### Health Check

Use the following command to verify Grafana is running properly:

```bash
curl -u admin:{PASSWORD} http://{ALB_DNS}/grafana/api/health
```

### Prometheus Connection

To verify Prometheus connectivity:

1. Log in to Grafana
2. Go to Configuration > Data Sources
3. Select the Prometheus data source
4. Click "Test" to verify the connection

### Backup Verification

To manually trigger a backup:

```bash
aws lambda invoke --function-name grafana-backup out.json
```

## Troubleshooting

### Common Issues

1. **Cannot access Grafana**:

   - Verify the ALB listener rule is correctly configured
   - Check security group rules allow traffic from ALB to Grafana
   - Ensure Grafana service is running (`aws ecs describe-services --cluster prod-e-cluster --services grafana-service`)

2. **Dashboards not loading**:

   - Check Prometheus data source connection
   - Verify the ALB DNS in the data source configuration matches the actual ALB DNS

3. **EFS mount issues**:
   - Check EFS mount target is in the same subnet as the Grafana task
   - Verify security group rules allow NFS traffic (port 2049)
   - Check EFS access point configuration

## Future Enhancements

1. **High Availability**:

   - Multi-AZ deployment for fault tolerance
   - Redundant EFS mount targets

2. **Security Improvements**:

   - HTTPS configuration with ACM certificate
   - Integration with an identity provider for SSO

3. **Advanced Monitoring**:
   - Additional dashboards for database metrics
   - Business KPI dashboards
   - Custom alert thresholds based on historical data

## Cost Considerations

The current implementation is optimized for cost efficiency:

- Single-AZ deployment reduces Fargate costs
- EFS lifecycle policy reduces storage costs for infrequently accessed data
- Minimal Fargate resources (0.25 vCPU, 0.5GB RAM)

Estimated monthly cost: ~$15
