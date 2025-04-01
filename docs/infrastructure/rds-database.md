# RDS PostgreSQL Database

## Overview

This document describes the Amazon RDS PostgreSQL database infrastructure components created for the project.

## Architecture

The database architecture consists of:

- A PostgreSQL RDS instance (`prod-e-db`) in private subnets across multiple Availability Zones.
- Security groups allowing access only from necessary services (e.g., ECS tasks) on port 5432.
- A DB Subnet Group specifying the private subnets for the instance.
- Database credentials managed securely via AWS Secrets Manager.

## Components

### RDS Instance

The PostgreSQL RDS instance (`prod-e-db`) is configured as follows:

- Engine: PostgreSQL 14.17
- Instance Class: db.t3.micro
- Storage: 20 GB (General Purpose SSD - gp2)
- Multi-AZ: Enabled (Utilizing a multi-AZ DB Subnet Group)
- Location: us-west-2 (deployed across AZs specified in the subnet group)
- Publicly Accessible: No
- Port: 5432
- Database Name: `appdb` (or as specified in initial setup)
- Master Credentials: Managed via AWS Secrets Manager (`prod-e/db-credentials`)
- Skip Final Snapshot: Yes (for easy cleanup in non-production stages)

### Security Group

The database security group (`db-security-group`) controls traffic to the RDS instance:

- Inbound rules:
  - Allow PostgreSQL (port 5432) from the ECS Task Security Group (`ecs-security-group`).
- Outbound rules:
  - None explicitly defined (defaults to allow all, but typically not required for RDS).

### DB Subnet Group

A DB subnet group (`db-subnet-group`) is created for the RDS instance:

- Includes private subnets across at least two Availability Zones (e.g., `private-subnet-a`, `private-subnet-b`).
- Ensures the RDS instance can operate in a highly available configuration.

## Security Considerations

- **Network Isolation**: The database resides in private subnets, inaccessible directly from the internet.
- **Restricted Access**: Security groups limit inbound traffic to only necessary sources (ECS tasks).
- **Credentials Management**: Secrets Manager securely handles database credentials, avoiding hardcoding.
- **Encryption**: Consider enabling encryption at rest for enhanced data protection.
- **IAM Permissions**: Ensure database access via IAM roles/policies follows the principle of least privilege (if using IAM DB Authentication).

## Backup and Recovery

- **Automated Snapshots**: AWS RDS provides automated snapshot capabilities.
- **Manual Snapshots**: Can be created via the console/CLI.
- **Backup Script**: A script (`scripts/backup/backup-database.sh`) exists for potentially automating snapshot creation (needs verification/review).
- **Point-in-Time Recovery**: Enabled if automated backups are configured.

## Future Enhancements / Considerations

- **Read Replicas**: Add read replicas for scaling read traffic.
- **Parameter Groups**: Customize database parameters for performance tuning.
- **Monitoring**: Enhance monitoring with CloudWatch custom metrics or Performance Insights.
- **Automatic Minor Version Upgrades**: Enable for automated patching.

---

**Last Updated**: [Current Date - will be filled by system]
**Version**: 1.1
