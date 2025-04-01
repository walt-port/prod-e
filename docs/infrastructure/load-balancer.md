# Application Load Balancer (ALB)

## Overview

This document describes the Application Load Balancer infrastructure components created for the project. Our ALB is named `prod-e-alb`.

## Architecture

The ALB architecture consists of:

- An external-facing Application Load Balancer (`prod-e-alb`) in the public subnet
- Security groups configured to allow HTTP traffic
- Target groups for different services (backend, Prometheus, and Grafana)
- HTTP listeners with routing rules for each service

## Components

### Application Load Balancer

The ALB (`prod-e-alb`) is configured as follows:

- Type: Application Load Balancer (Layer 7)
- Name: prod-e-alb
- Accessibility: Internet-facing (not internal)
- Location: Public subnet in us-west-2a
- Deletion Protection: Disabled (for easy cleanup in development)

### Security Group

The ALB security group (`alb-security-group`) controls traffic to and from the load balancer:

- Inbound rules:
  - Allow HTTP (port 80) from anywhere (0.0.0.0/0)
- Outbound rules:
  - Allow all outbound traffic to anywhere (0.0.0.0/0)

### Target Groups

Multiple target groups are configured for our services:

1. **Backend Service Target Group** (`ecs-target-group`):

   - Target type: IP (for compatibility with ECS Fargate)
   - Port: 3000
   - Protocol: HTTP
   - Health check:
     - Path: /health
     - Success codes: 200-299
     - Interval: 30 seconds
     - Timeout: 5 seconds
     - Healthy threshold: 3
     - Unhealthy threshold: 3

2. **Prometheus Target Group** (`prometheus-tg`):

   - Target type: IP
   - Port: 9090
   - Protocol: HTTP
   - Health check:
     - Path: /-/healthy
     - Success codes: 200-299

3. **Grafana Target Group** (`grafana-tg`):
   - Target type: IP
   - Port: 3000
   - Protocol: HTTP
   - Health check:
     - Path: /api/health
     - Success codes: 200-299

### HTTP Listener

The ALB has an HTTP listener on port 80 with path-based routing:

- Default rule: Routes to the backend service target group
- Path-based rules:
  - `/prometheus*`: Routes to the Prometheus target group
  - `/grafana*`: Routes to the Grafana target group

## Accessing Services

Services can be accessed using the ALB DNS name:

```bash
# Get the ALB DNS name
$ aws elbv2 describe-load-balancers --names prod-e-alb --query "LoadBalancers[0].DNSName" --output text
```

Using the returned DNS name, services can be accessed at:

- Backend: http://{ALB_DNS}/
- Prometheus: http://{ALB_DNS}/prometheus/
- Grafana: http://{ALB_DNS}/grafana/

## Future Enhancements

Planned enhancements for the ALB include:

- Configuring HTTPS with SSL/TLS certificates
- Implementing sticky sessions if needed
- Adding AWS WAF integration for security

---

**Last Updated**: [Current Date - will be filled by system]
**Version**: 1.1
