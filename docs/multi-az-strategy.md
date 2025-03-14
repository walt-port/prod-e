# Multi-AZ Strategy

## Overview

This document outlines the strategy for expanding the current single availability zone (AZ) infrastructure to a multi-AZ deployment for improved reliability and fault tolerance.

## Current State

The current infrastructure is deployed in a single availability zone (us-west-2a) for simplicity and cost-effectiveness during the initial development phase. This includes:

- VPC spanning the entire region
- Public subnet in us-west-2a
- Private subnet in us-west-2a
- Internet Gateway for public internet access
- Application Load Balancer in the public subnet
- RDS PostgreSQL instance in the private subnet (single-AZ)
- ECS Fargate service in the private subnet

## Multi-AZ Enhancement Plan

### Network Layer

1. **Additional Subnets**:

   - Add public subnets in us-west-2b and us-west-2c
   - Add private subnets in us-west-2b and us-west-2c

2. **NAT Gateways**:

   - Add NAT Gateways in each public subnet to allow outbound internet access for resources in private subnets
   - Update route tables for private subnets to route internet-bound traffic through the NAT Gateways

3. **Route Tables**:
   - Create additional route tables for each new subnet
   - Configure proper routing between all subnets

### Compute Layer

1. **ECS Service**:

   - Update ECS service to deploy tasks across multiple AZs
   - Configure the service to balance tasks across all private subnets

2. **Auto-scaling**:
   - Implement service auto-scaling to handle load changes
   - Set appropriate scaling triggers based on CPU and memory utilization

### Data Layer

1. **RDS PostgreSQL**:

   - Enable Multi-AZ deployment for the RDS instance
   - Configure automatic failover to the standby instance

2. **ElastiCache (Optional)**:
   - Deploy across multiple AZs if added in the future
   - Configure replication groups with replicas in different AZs

### Application Delivery Layer

1. **Application Load Balancer**:
   - Update the ALB to span all public subnets
   - Configure proper health checks and routing to the ECS tasks

### High Availability Considerations

1. **Data Replication**:

   - Ensure proper data replication between AZs for stateful services
   - Implement read replicas if high read throughput is required

2. **Service Discovery**:

   - Implement service discovery mechanisms to locate healthy services
   - Utilize AWS CloudMap or equivalent service

3. **Backup and Disaster Recovery**:
   - Configure automated backups with cross-region replication
   - Define clear recovery point objectives (RPO) and recovery time objectives (RTO)

## Implementation Steps

1. **Update Infrastructure Code**:

   - Modify the CDKTF code to include resources in additional AZs
   - Parameterize AZ selection to make it configurable

2. **Testing Strategy**:

   - Test failover scenarios to ensure high availability
   - Verify that applications can withstand the loss of an AZ

3. **Monitoring and Alerting**:

   - Set up monitoring across all AZs
   - Configure alerts for AZ-specific issues

4. **Deployment Strategy**:
   - Implement a rolling deployment strategy that maintains availability
   - Minimize downtime during the transition

## Cost Implications

Implementing a multi-AZ architecture will increase costs due to:

- Additional NAT Gateways (one per AZ)
- Multi-AZ RDS deployment (nearly doubles the cost)
- Increased data transfer between AZs
- Additional infrastructure resources

Estimated cost increase: ~60-80% compared to single-AZ deployment.

## Conclusion

Moving to a multi-AZ architecture is an important step for production readiness. While the current single-AZ deployment is sufficient for development and testing, a multi-AZ approach will provide the reliability and fault tolerance required for a production environment.
