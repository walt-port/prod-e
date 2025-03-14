# Application Load Balancer (ALB)

## Overview

This document describes the Application Load Balancer infrastructure components created for the project.

## Architecture

The ALB architecture consists of:

- An external-facing Application Load Balancer in the public subnet
- Security groups configured to allow HTTP traffic
- A target group for future service registration
- A default HTTP listener with a 503 response

## Components

### Application Load Balancer

The ALB is configured as follows:

- Type: Application Load Balancer (Layer 7)
- Accessibility: Internet-facing (not internal)
- Location: Public subnet in us-west-2a
- Deletion Protection: Disabled (for easy cleanup in development)

### Security Group

The ALB security group controls traffic to and from the load balancer:

- Inbound rules:
  - Allow HTTP (port 80) from anywhere (0.0.0.0/0)
- Outbound rules:
  - Allow all outbound traffic to anywhere (0.0.0.0/0)

### Target Group

A target group is created but not yet associated with any targets:

- Target type: IP (for future compatibility with ECS Fargate)
- Port: 80
- Protocol: HTTP
- Health check:
  - Path: /
  - Success codes: 200-299
  - Interval: 30 seconds
  - Timeout: 5 seconds
  - Healthy threshold: 3
  - Unhealthy threshold: 3

### HTTP Listener

The ALB has an HTTP listener on port 80:

- Default action: Fixed response
  - Status code: 503
  - Content type: text/plain
  - Message: "Service Unavailable"

## Future Enhancements

Planned enhancements for the ALB include:

- Configuring HTTPS with SSL/TLS certificates
- Setting up routing rules for different services
- Implementing sticky sessions if needed
- Adding AWS WAF integration for security
- Adding proper targets to the target group when services are deployed
