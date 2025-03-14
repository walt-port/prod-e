# Infrastructure Documentation Overview

## Introduction

This document serves as the main index for all infrastructure documentation in this project. The project uses Cloud Development Kit for Terraform (CDKTF) with TypeScript to define and deploy AWS infrastructure components.

## Available Documentation

| Component                 | Description                                                          | Document Link                                  |
| ------------------------- | -------------------------------------------------------------------- | ---------------------------------------------- |
| VPC and Networking        | Documentation about VPC, subnets, Internet Gateway, and routing      | [vpc-networking.md](./vpc-networking.md)       |
| Application Load Balancer | Documentation about ALB, target groups, and listeners                | [load-balancer.md](./load-balancer.md)         |
| RDS PostgreSQL Database   | Documentation about RDS instance, security groups, and subnet groups | [rds-database.md](./rds-database.md)           |
| ECS Fargate Service       | Documentation about ECS cluster, task definition, and service        | [ecs-fargate.md](./ecs-fargate.md)             |
| Multi-AZ Strategy         | Documentation of current multi-AZ implementation and future plans    | [multi-az-strategy.md](./multi-az-strategy.md) |

## Infrastructure Overview

The current infrastructure consists of:

1. **Base Network Layer**

   - VPC with public and private subnets in two availability zones (us-west-2a and us-west-2b)
   - Internet Gateway for public internet access
   - Route tables and associations for both public and private subnets

2. **Application Delivery Layer**

   - Application Load Balancer (ALB) spanning multiple AZs
   - Target groups for ECS service integration
   - Security groups for controlling traffic

3. **Data Storage Layer**

   - PostgreSQL RDS instance (currently single-AZ but with multi-AZ subnet group)
   - Database subnet group spanning multiple AZs
   - Security groups for database access

4. **Compute Layer**
   - ECS Fargate cluster
   - Task definition with minimal resources (0.25 vCPU, 0.5GB memory)
   - ECS service with a Node.js 16 container
   - IAM roles for execution permissions

## Deployment Status

The infrastructure has been successfully deployed with the following components:

- VPC (vpc-id): vpc-0fc6af22ecf8449ff
- ALB DNS name: application-load-balancer-98932456.us-west-2.elb.amazonaws.com
- ECS cluster: prod-e-cluster
- RDS endpoint: postgres-instance.cnymcgs0e26q.us-west-2.rds.amazonaws.com:5432

## Deployment Instructions

To deploy this infrastructure:

1. Ensure you have the necessary prerequisites:

   - Node.js (v18+)
   - Terraform CLI
   - CDKTF CLI
   - AWS CLI configured with appropriate credentials

2. Install dependencies:

   ```bash
   npm install
   cdktf get
   ```

3. Synthesize Terraform configuration:

   ```bash
   npm run synth
   ```

4. Deploy the infrastructure:

   ```bash
   npm run deploy
   ```

## Troubleshooting Common Issues

During deployment, you may encounter the following issues:

1. **RDS Username Reserved Word Error**:

   - Error message: `InvalidParameterValue: MasterUsername admin cannot be used as it is a reserved word used by the engine`
   - Resolution: Change the username to something other than 'admin' in the configuration

2. **Subnet Requirements for Services**:
   - ALB requires subnets in at least two availability zones
   - RDS DB subnet group requires subnets in at least two availability zones
   - Resolution: Add additional subnets in a second AZ

## Teardown Instructions

There are two options for tearing down the infrastructure:

### Option 1: Using CDKTF (Simple)

This is the recommended approach for most cases:

```bash
npm run destroy
```

### Option 2: Using Python Teardown Script (Advanced)

For more control and visibility into the teardown process:

1. Ensure you have Python and boto3 installed:

   ```bash
   pip install boto3
   ```

2. Run the teardown script:

   ```bash
   python scripts/teardown.py
   ```

3. For a dry run (to see what would be deleted without actually deleting):
   ```bash
   python scripts/teardown.py --dry-run
   ```

See the [scripts README](../scripts/README.md) for more details.

## Environment Configuration

The infrastructure is designed with configuration parameters that can be adjusted in the `config` object in `main.ts`. Key configuration parameters include:

- AWS region: us-west-2
- VPC CIDR: 10.0.0.0/16
- Public subnet CIDR: 10.0.1.0/24
- Private subnet CIDR: 10.0.2.0/24
- Database settings: instance class, engine version, credentials, etc.
- ECS settings: CPU, memory, image, container port, etc.

## Future Plans

The infrastructure is designed to be expanded in the future. Planned enhancements include:

- Multi-AZ deployment for high availability (see [multi-az-strategy.md](./multi-az-strategy.md))
- Proper Node.js/Express API for the ECS service
- Prometheus and Grafana for monitoring
- React frontend for visualization
- CI/CD pipeline with GitHub Actions
- S3 buckets for static content and file storage
- CloudWatch for monitoring and alarming
