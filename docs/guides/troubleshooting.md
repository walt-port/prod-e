# Troubleshooting Guide

## Overview

This document provides a comprehensive guide for troubleshooting common issues with the Production Experience Showcase project. It covers infrastructure, application, monitoring, and deployment problems with step-by-step resolution procedures.

## Table of Contents

- [Infrastructure Issues](#infrastructure-issues)
- [Application Issues](#application-issues)
- [Monitoring Issues](#monitoring-issues)
- [Deployment Issues](#deployment-issues)
- [Database Issues](#database-issues)
- [Security Issues](#security-issues)
- [Related Documentation](#related-documentation)

## Infrastructure Issues

### Failed Infrastructure Deployment

#### Symptoms

- Terraform apply fails with error messages
- Resources are partially created

#### Resolution Steps

1. Check Terraform logs for specific error messages:

   ```bash
   $ cd cdktf.out/stacks/prod-e
   $ terraform apply -v
   ```

2. Common errors and solutions:
   - **State lock error**: Release the lock manually
     ```bash
     $ aws dynamodb delete-item \
       --table-name prod-e-terraform-lock \
       --key '{"LockID": {"S": "prod-e-terraform-state/terraform.tfstate-md5"}}'
     ```
   - **IAM permissions error**: Verify IAM permissions for the deploying user/role
   - **Resource already exists**: Import existing resources into state
     ```bash
     $ terraform import aws_resource.name resource_id
     ```

### Security Group Connectivity Issues

#### Symptoms

- Services cannot communicate with each other
- External access to ALB fails

#### Resolution Steps

1. Verify security group rules:

   ```bash
   $ aws ec2 describe-security-groups --group-ids sg-xxx
   ```

2. Check for missing ingress/egress rules:
   ```bash
   $ aws ec2 authorize-security-group-ingress \
     --group-id sg-xxx \
     --protocol tcp \
     --port 3000 \
     --source-group sg-yyy
   ```

### Network Connectivity Issues

#### Symptoms

- Resources in private subnets cannot reach the internet
- Services in different subnets cannot communicate

#### Resolution Steps

1. Verify NAT Gateway status:

   ```bash
   $ aws ec2 describe-nat-gateways
   ```

2. Check route tables and associations:

   ```bash
   $ aws ec2 describe-route-tables
   $ aws ec2 describe-route-table-associations
   ```

3. Verify subnet configurations:
   ```bash
   $ aws ec2 describe-subnets --subnet-ids subnet-xxx
   ```

## Application Issues

### ECS Service Fails to Start

#### Symptoms

- Tasks showing as STOPPED in ECS console
- Service shows 0 running tasks

#### Resolution Steps

1. Check task status and reason:

   ```bash
   $ aws ecs describe-tasks \
     --cluster prod-e-cluster \
     --tasks $(aws ecs list-tasks --cluster prod-e-cluster --query "taskArns" --output text)
   ```

2. Check CloudWatch logs for specific error messages:

   ```bash
   $ aws logs get-log-events \
     --log-group-name /ecs/prod-e-backend \
     --log-stream-name ecs/backend/latest
   ```

3. Common issues and solutions:
   - **Container cannot be pulled**: Check ECR permissions
   - **Resource constraints**: Increase task CPU/memory
   - **Health check failure**: Verify health check endpoint is working
   - **Environment variables missing**: Check task definition

### Application Load Balancer Issues

#### Symptoms

- 503 Service Unavailable errors
- Target health checks failing

#### Resolution Steps

1. Check target group health:

   ```bash
   $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...
   ```

2. Verify target group and listener configuration:

   ```bash
   $ aws elbv2 describe-target-groups --load-balancer-arn $(aws elbv2 describe-load-balancers --names prod-e-alb --query "LoadBalancers[0].LoadBalancerArn" --output text)
   $ aws elbv2 describe-listeners --load-balancer-arn $(aws elbv2 describe-load-balancers --names prod-e-alb --query "LoadBalancers[0].LoadBalancerArn" --output text)
   ```

3. Check ALB security groups allow traffic on appropriate ports

### API Endpoint Issues

#### Symptoms

- API endpoints return errors
- Specific HTTP status codes (4xx, 5xx)

#### Resolution Steps

1. Check application logs for error messages
2. Verify API route configuration
3. Check database connectivity from the application
4. Test endpoint directly from within the container:
   ```bash
   $ aws ecs execute-command \
     --cluster prod-e-cluster \
     --task task-id \
     --container backend \
     --command "/bin/sh" \
     --interactive
   ```

## Monitoring Issues

### Prometheus Scraping Issues

#### Symptoms

- Missing metrics in Prometheus
- Target shows as DOWN in Prometheus targets page

#### Resolution Steps

1. Verify Prometheus configuration:

   ```bash
   $ aws ecs execute-command \
     --cluster prod-e-cluster \
     --task prometheus-task-id \
     --container prometheus \
     --command "/bin/sh" \
     --interactive
   ```

2. Check `/etc/prometheus/prometheus.yml` inside the container
3. Verify target application exposes `/metrics` endpoint:

   ```bash
   $ curl http://backend-service:3000/metrics
   ```

4. Check security group rules allow Prometheus to access target

### Grafana Configuration Issues

#### Symptoms

- Grafana dashboards show no data
- Data source connectivity errors

#### Resolution Steps

1. Verify Prometheus data source configuration in Grafana
2. Check Grafana logs:

   ```bash
   $ aws logs get-log-events \
     --log-group-name /ecs/grafana \
     --log-stream-name ecs/grafana/latest
   ```

3. Verify Prometheus is accessible from Grafana container:
   ```bash
   $ aws ecs execute-command \
     --cluster prod-e-cluster \
     --task grafana-task-id \
     --container grafana \
     --command "/bin/sh" \
     --interactive
   $ curl http://prometheus-service:9090/api/v1/query?query=up
   ```

### Missing or Incomplete Metrics

#### Symptoms

- Expected metrics not showing in dashboards
- Incomplete data for specific time ranges

#### Resolution Steps

1. Verify application is correctly instrumented:

   ```javascript
   // Example Node.js metrics setup
   const client = require('prom-client');
   const counter = new client.Counter({
     name: 'metric_name',
     help: 'metric_help',
   });
   ```

2. Check scrape interval and retention settings in Prometheus
3. Verify no network issues between Prometheus and targets

## Deployment Issues

### CI/CD Pipeline Failures

#### Symptoms

- GitHub Actions workflow fails
- Specific step in the pipeline fails

#### Resolution Steps

1. Review the GitHub Actions logs for specific error messages
2. Check common issues:
   - **AWS credentials**: Verify GitHub repository secrets
   - **Docker build failures**: Check Dockerfile and build context
   - **Test failures**: Run tests locally to reproduce
   - **Deployment failures**: Check Terraform/CDKTF logs

### Container Image Issues

#### Symptoms

- Container fails to start
- Application crashes on startup

#### Resolution Steps

1. Pull and run the image locally:

   ```bash
   $ aws ecr get-login-password | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
   $ docker pull <account-id>.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:latest
   $ docker run -p 3000:3000 <account-id>.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:latest
   ```

2. Check for common issues:
   - Missing environment variables
   - Incorrect entry point
   - Permission issues

## Database Issues

### RDS Connectivity Issues

#### Symptoms

- Application cannot connect to database
- "Connection refused" or timeout errors

#### Resolution Steps

1. Verify security group allows traffic from application to RDS:

   ```bash
   $ aws ec2 describe-security-groups --group-ids sg-database
   ```

2. Check RDS instance status:

   ```bash
   $ aws rds describe-db-instances --db-instance-identifier postgres-instance
   ```

3. Test connectivity from application container:
   ```bash
   $ aws ecs execute-command \
     --cluster prod-e-cluster \
     --task task-id \
     --container backend \
     --command "/bin/sh" \
     --interactive
   $ nc -zv postgres-instance.xxx.us-west-2.rds.amazonaws.com 5432
   ```

### Database Performance Issues

#### Symptoms

- Slow query responses
- High CPU/memory utilization on RDS instance

#### Resolution Steps

1. Check RDS metrics in CloudWatch:

   ```bash
   $ aws cloudwatch get-metric-statistics \
     --namespace AWS/RDS \
     --metric-name CPUUtilization \
     --dimensions Name=DBInstanceIdentifier,Value=postgres-instance \
     --start-time 2025-03-14T00:00:00Z \
     --end-time 2025-03-15T00:00:00Z \
     --period 300 \
     --statistics Average
   ```

2. Analyze slow query logs:

   ```bash
   $ aws rds download-db-log-file-portion \
     --db-instance-identifier postgres-instance \
     --log-file-name postgresql.log
   ```

3. Consider scaling options:
   - Increase instance size
   - Read replicas for read-heavy workloads
   - Index optimization

## Security Issues

### IAM Permission Issues

#### Symptoms

- "Access Denied" errors in AWS API calls
- Services cannot access required resources

#### Resolution Steps

1. Check IAM policy for the role:

   ```bash
   $ aws iam get-role-policy \
     --role-name prod-e-execution-role \
     --policy-name policy-name
   ```

2. Verify trust relationship:

   ```bash
   $ aws iam get-role \
     --role-name prod-e-execution-role
   ```

3. Add missing permissions if needed:
   ```bash
   $ aws iam put-role-policy \
     --role-name prod-e-execution-role \
     --policy-name policy-name \
     --policy-document file://policy.json
   ```

### Secrets Management Issues

#### Symptoms

- Application cannot access secrets
- "Access Denied" when accessing Secrets Manager

#### Resolution Steps

1. Verify IAM permissions for Secrets Manager:

   ```bash
   $ aws iam simulate-principal-policy \
     --policy-source-arn arn:aws:iam::account-id:role/prod-e-execution-role \
     --action-names secretsmanager:GetSecretValue \
     --resource-arns arn:aws:secretsmanager:us-west-2:account-id:secret:prod-e-secrets
   ```

2. Check secret exists and is correctly formatted:
   ```bash
   $ aws secretsmanager describe-secret \
     --secret-id prod-e-secrets
   ```

## Related Documentation

- [Deployment Guide](./deployment-guide.md)
- [Monitoring Documentation](./monitoring.md)
- [Network Architecture](./network-architecture.md)
- [ECS Service Documentation](./ecs-service.md)

---

**Last Updated**: 2025-03-15
**Version**: 1.0
