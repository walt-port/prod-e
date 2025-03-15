# RDS PostgreSQL Database

## Overview

This document describes the Amazon RDS PostgreSQL database infrastructure components created for the project.

## Architecture

The database architecture consists of:

- A PostgreSQL RDS instance in the private subnet
- Security groups allowing access on port 5432
- Subnet groups for the database instance
- Configuration for database credentials and connection parameters

## Components

### RDS Instance

The PostgreSQL RDS instance is configured as follows:

- Engine: PostgreSQL 14.10
- Instance Class: db.t3.micro
- Storage: 20 GB
- Multi-AZ: Disabled (single AZ deployment)
- Location: us-west-2a (same as private subnet)
- Publicly Accessible: Yes (for development purposes only)
- Port: 5432
- Database Name: appdb
- Master Username: admin
- Skip Final Snapshot: Yes (for easy cleanup in development)

### Security Group

The database security group controls traffic to and from the RDS instance:

- Inbound rules:
  - Allow PostgreSQL (port 5432) from anywhere (0.0.0.0/0)
    - Note: This is for development purposes only. In production, this should be restricted to specific sources.
- Outbound rules:
  - Allow all outbound traffic to anywhere (0.0.0.0/0)

### DB Subnet Group

A DB subnet group is created for the RDS instance:

- Includes both private and public subnets (to meet the minimum requirement of two subnets)
- Used by the RDS instance to determine which subnets and IP addresses to use

## Security Considerations

The current configuration makes the database publicly accessible for development purposes. In a production environment, consider:

- Restricting access to specific IP addresses or security groups
- Disabling public accessibility
- Enabling encryption at rest
- Implementing proper IAM permissions
- Enabling Multi-AZ deployment for high availability

## Future Enhancements

Planned enhancements for the database include:

- Implementing proper backup and restore procedures
- Adding read replicas for improved performance
- Setting up parameter groups for database optimization
- Implementing proper monitoring and alerting
- Configuring automatic minor version upgrades
