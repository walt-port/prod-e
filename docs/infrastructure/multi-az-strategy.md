# Multi-AZ Strategy

## Overview

This document outlines the strategy for expanding the current single availability zone (AZ) infrastructure to a multi-AZ deployment for improved reliability and fault tolerance.

## Current State

The infrastructure is now deployed across multiple availability zones (us-west-2a and us-west-2b) for improved reliability and to meet AWS requirements. The current implementation includes:

- VPC spanning the entire region
- Public subnets in us-west-2a and us-west-2b
- Private subnets in us-west-2a and us-west-2b
- Internet Gateway for public internet access
- Application Load Balancer spanning both public subnets
- RDS PostgreSQL instance with subnet group covering multiple AZs
- ECS Fargate service in the private subnet

## Implementation Details

### Network Layer

1. **Subnet Implementation**:

   - Public subnet in us-west-2a: 10.0.1.0/24
   - Public subnet in us-west-2b: 10.0.3.0/24
   - Private subnet in us-west-2a: 10.0.2.0/24
   - Private subnet in us-west-2b: 10.0.4.0/24

2. **Internet Gateway**:

   - Single Internet Gateway attached to the VPC
   - Public route tables configured to route internet-bound traffic through the gateway

3. **Route Tables**:
   - Public route table with routes to the Internet Gateway
   - Private route table for internal traffic
   - Associations to respective subnets

### Application Delivery Layer

1. **Application Load Balancer**:
   - Spans both public subnets (us-west-2a and us-west-2b)
   - Security group allowing HTTP traffic from the internet
   - Target group configured for the ECS service

### Data Layer

1. **RDS PostgreSQL**:
   - DB subnet group includes private subnets in both us-west-2a and us-west-2b
   - Currently deployed as single-AZ for cost efficiency, but with multi-AZ subnet group
   - Using PostgreSQL 14.17

### Compute Layer

1. **ECS Service**:
   - Currently deployed in the private subnet in us-west-2a
   - Task definition with Node.js 16 container image
   - Security group allowing traffic only from the ALB

## Lessons Learned

During the implementation, we encountered several important AWS requirements:

1. **RDS Subnet Group Requirements**:

   - AWS requires DB subnet groups to span at least two AZs, even for single-AZ database deployments
   - This requirement necessitated adding a second private subnet

2. **ALB Requirements**:

   - Application Load Balancers must have subnets in at least two AZs
   - This requirement led to adding a second public subnet

3. **Database Naming Restrictions**:
   - 'admin' is a reserved word in PostgreSQL and cannot be used as a master username
   - We updated the configuration to use 'dbadmin' instead

## Future Enhancements

While we've implemented multi-AZ networking, further enhancements can improve the architecture:

1. **NAT Gateways**:

   - Add NAT Gateways in each public subnet to allow outbound internet access for resources in private subnets
   - Update route tables for private subnets to route internet-bound traffic through the NAT Gateways

2. **ECS Service Improvements**:

   - Update ECS service to deploy tasks across both private subnets
   - Configure the service to balance tasks across all AZs

3. **RDS Multi-AZ**:

   - Enable true Multi-AZ deployment for the RDS instance (currently single-AZ with multi-AZ subnet group)
   - Configure automatic failover to the standby instance

4. **Auto-scaling**:
   - Implement service auto-scaling to handle load changes
   - Set appropriate scaling triggers based on CPU and memory utilization

## Cost Implications

The current multi-AZ network setup has minimal cost impact compared to a single-AZ deployment. However, implementing full multi-AZ for all services will increase costs:

- Multi-AZ RDS deployment would nearly double the database cost
- NAT Gateways (one per AZ) would add approximately $32/month per gateway
- Additional data transfer between AZs

Full multi-AZ implementation estimated cost increase: ~60-80% compared to single-AZ deployment.

## Conclusion

The infrastructure now has multi-AZ networking, meeting AWS requirements for ALB and RDS subnet groups. This provides a foundation for true high availability, though some components (like the RDS instance and ECS tasks) are still effectively single-AZ deployments. Future enhancements can build on this foundation to achieve full multi-AZ redundancy.
