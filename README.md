# 🚀 The Production Experience Showcase (prod-e)

A platform demonstrating DevOps/SRE skills by building a monitoring and alerting dashboard system with modern infrastructure practices. This project addresses the common "production experience" barrier in job searches by creating a practical, functional system with industry-standard technologies.

## 📋 Project Overview

This project implements a complete cloud infrastructure with monitoring capabilities:

- AWS infrastructure using the Cloud Development Kit for Terraform (CDKTF) with TypeScript
- Containerized backend services with ECS Fargate
- API service built with Node.js/Express
- PostgreSQL database for data storage
- Prometheus and Grafana for metrics collection and visualization
- Modern React/TypeScript frontend for the dashboard
- CI/CD automation with GitHub Actions

## 🛠️ Technology Stack

### 🌩️ Infrastructure & Cloud

- AWS (Amazon Web Services)
- CDKTF (Cloud Development Kit for Terraform)
- Terraform
- Docker & Container Technologies
- IAM (Identity and Access Management)

### 🖥️ Backend

- Node.js
- Express
- PostgreSQL
- ECS Fargate

### 🔍 Monitoring & Observability

- Prometheus
- Grafana
- CloudWatch

### 🧠 AI Assistance

- Claude
- Cursor
- Grok

## 🏗️ Infrastructure Components

This project sets up the following AWS resources:

### 🌐 Networking

- VPC with DNS support and DNS hostnames
- Public subnets in us-west-2a (10.0.1.0/24) and us-west-2b (10.0.3.0/24)
- Private subnets in us-west-2a (10.0.2.0/24) and us-west-2b (10.0.4.0/24)
- Internet Gateway for public internet access
- Route tables with proper routing configuration
- Application Load Balancer for traffic management (spanning multiple AZs)

### 💻 Compute

- ECS Fargate for containerized services
- Single task with minimal resources (0.25 vCPU, 0.5GB memory)
- Containerized Node.js/Express API

### 💾 Data Storage

- RDS PostgreSQL instance (db.t3.micro) with subnet group spanning multiple AZs
- Prometheus time series database for metrics (to be implemented)

### 📊 Monitoring & Visualization

- Prometheus for metrics collection
- Grafana for dashboard visualization
- CloudWatch for AWS service monitoring

## 🏛️ Infrastructure Design

The infrastructure is deployed across multiple availability zones (us-west-2a and us-west-2b) for high availability. The design includes:

- Public subnets in two AZs with direct internet access through an Internet Gateway
- Private subnets in two AZs for ECS Fargate services and RDS
- Application Load Balancer spanning multiple AZs for fault tolerance
- RDS PostgreSQL database with a subnet group covering multiple AZs

### 🆕 Recent Improvements

The infrastructure was recently updated to support AWS requirements for multi-AZ deployments:

- Application Load Balancer now spans both us-west-2a and us-west-2b
- RDS database subnet group includes subnets in both us-west-2a and us-west-2b
- PostgreSQL username was updated to comply with reserved word restrictions

## ⏱️ Implementation Timeline

The project is being implemented over a 4-day timeline:

1. **Day 1**: Infrastructure Setup (VPC, ALB, RDS, ECS)
2. **Day 2**: Backend Services & Monitoring (Node.js API, Prometheus, Grafana)
3. **Day 3**: Frontend Dashboard (React, TypeScript, metrics visualization)
4. **Day 4**: CI/CD, Testing & Polish (GitHub Actions, documentation)

## 📋 Prerequisites

- Node.js (v14+)
- Terraform CLI
- CDKTF CLI
- AWS CLI configured with appropriate credentials
- Docker (for local container development)

## 🔧 Installation

```bash
# Install dependencies
npm install

# Generate CDKTF providers
cdktf get
```

## 📝 Usage

```bash
# Synthesize Terraform configuration
npm run synth

# Deploy infrastructure
npm run deploy

# Destroy infrastructure
npm run destroy
```

## 📁 Project Structure

- `main.ts` - Main CDKTF code that defines the infrastructure
- `cdktf.json` - CDKTF configuration file
- `package.json` - Node.js package configuration
- `tsconfig.json` - TypeScript configuration
- `docs/` - Project documentation
- `backend/` - Node.js/Express API service (to be added)
- `frontend/` - React/TypeScript frontend (to be added)

## ⚙️ Customization

To modify the infrastructure:

1. Update the configuration in the `config` object in `main.ts`
2. Add or modify AWS resources in the `MyStack` class
3. Run `npm run synth` to generate updated Terraform configuration

## 💰 Cost Considerations

This project is designed to be cost-effective for demonstration purposes:

- Estimated monthly cost: ~$42-43
- ECS Fargate: ~$10
- RDS PostgreSQL: ~$15
- Application Load Balancer: ~$16
- Data Transfer: ~$1-2

Resources can be shut down after demonstration to avoid ongoing costs.

## ⚠️ Known Issues and Resolutions

During deployment, we encountered and resolved the following issues:

1. **RDS DB Subnet Group Requirement**: AWS requires RDS instances to have subnet groups spanning at least two AZs, even for single-AZ database deployments. We resolved this by adding a second private subnet in us-west-2b.

2. **PostgreSQL Reserved Words**: 'admin' is a reserved word in PostgreSQL and cannot be used as a master username. We changed this to 'dbadmin'.
