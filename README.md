# The Production Experience Showcase (prod-e)

A platform demonstrating DevOps/SRE skills by building a monitoring and alerting dashboard system with modern infrastructure practices. This project addresses the common "production experience" barrier in job searches by creating a practical, functional system with industry-standard technologies.

## Project Overview

This project implements a complete cloud infrastructure with monitoring capabilities:

- AWS infrastructure using the Cloud Development Kit for Terraform (CDKTF) with TypeScript
- Containerized backend services with ECS Fargate
- API service built with Node.js/Express
- PostgreSQL database for data storage
- Prometheus and Grafana for metrics collection and visualization
- Modern React/TypeScript frontend for the dashboard
- CI/CD automation with GitHub Actions

## Infrastructure Components

This project sets up the following AWS resources:

### Networking

- VPC with DNS support and DNS hostnames
- Public subnet (10.0.1.0/24) in us-west-2a
- Private subnet (10.0.2.0/24) in us-west-2a
- Internet Gateway for public internet access
- Route tables with proper routing configuration
- Application Load Balancer for traffic management

### Compute

- ECS Fargate for containerized services
- Single task with minimal resources (0.25 vCPU, 0.5GB memory)
- Containerized Node.js/Express API

### Data Storage

- RDS PostgreSQL instance (db.t3.micro)
- Prometheus time series database for metrics

### Monitoring & Visualization

- Prometheus for metrics collection
- Grafana for dashboard visualization
- CloudWatch for AWS service monitoring

## Infrastructure Design

The current implementation uses a single availability zone (us-west-2a) for simplicity. The infrastructure includes:

- A public subnet with direct internet access through an Internet Gateway
- A private subnet for ECS Fargate services
- Application Load Balancer in the public subnet
- RDS PostgreSQL database in the private subnet

### Future Multi-AZ Plan

In the future, this infrastructure will be expanded to support multiple availability zones for high availability and fault tolerance. The planned enhancements include:

- Adding public and private subnets in multiple AZs (us-west-2b, us-west-2c)
- Implementing NAT Gateways for private subnet internet access
- Setting up proper routing between all subnets
- Configuring load balancers across multiple AZs

## Implementation Timeline

The project is being implemented over a 4-day timeline:

1. **Day 1**: Infrastructure Setup (VPC, ALB, RDS, ECS)
2. **Day 2**: Backend Services & Monitoring (Node.js API, Prometheus, Grafana)
3. **Day 3**: Frontend Dashboard (React, TypeScript, metrics visualization)
4. **Day 4**: CI/CD, Testing & Polish (GitHub Actions, documentation)

## Prerequisites

- Node.js (v14+)
- Terraform CLI
- CDKTF CLI
- AWS CLI configured with appropriate credentials
- Docker (for local container development)

## Installation

```bash
# Install dependencies
npm install

# Generate CDKTF providers
cdktf get
```

## Usage

```bash
# Synthesize Terraform configuration
npm run synth

# Deploy infrastructure
npm run deploy

# Destroy infrastructure
npm run destroy
```

## Project Structure

- `main.ts` - Main CDKTF code that defines the infrastructure
- `cdktf.json` - CDKTF configuration file
- `package.json` - Node.js package configuration
- `tsconfig.json` - TypeScript configuration
- `docs/` - Project documentation
- `backend/` - Node.js/Express API service (to be added)
- `frontend/` - React/TypeScript frontend (to be added)

## Customization

To modify the infrastructure:

1. Update the configuration in the `config` object in `main.ts`
2. Add or modify AWS resources in the `MyStack` class
3. Run `npm run synth` to generate updated Terraform configuration

## Cost Considerations

This project is designed to be cost-effective for demonstration purposes:

- Estimated monthly cost: ~$42-43
- ECS Fargate: ~$10
- RDS PostgreSQL: ~$15
- Application Load Balancer: ~$16
- Data Transfer: ~$1-2

Resources can be shut down after demonstration to avoid ongoing costs.
