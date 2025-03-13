# CDKTF AWS Project

This is a simple AWS infrastructure project using the Cloud Development Kit for Terraform (CDKTF) with TypeScript.

## Infrastructure Components

This project sets up the following AWS resources:

- VPC with DNS support and DNS hostnames
- Public subnet in us-west-2a
- Private subnet in us-west-2a (no public internet access)
- Internet Gateway for public internet access
- Route tables with proper routing configuration

## Infrastructure Design

The current implementation uses a single availability zone (us-west-2a) for simplicity. The infrastructure includes:

- A public subnet with direct internet access through an Internet Gateway
- A private subnet without direct internet access (intended for ECS Fargate services)

### Future Multi-AZ Plan

In the future, this infrastructure will be expanded to support multiple availability zones for high availability and fault tolerance. The planned enhancements include:

- Adding public and private subnets in multiple AZs (us-west-2b, us-west-2c)
- Implementing NAT Gateways for private subnet internet access if needed
- Setting up proper routing between all subnets
- Configuring load balancers across multiple AZs

## Prerequisites

- Node.js (v14+)
- Terraform CLI
- CDKTF CLI
- AWS CLI configured with appropriate credentials

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

## Customization

To modify the infrastructure:

1. Update the configuration in the `config` object in `main.ts`
2. Add or modify AWS resources in the `MyStack` class
3. Run `npm run synth` to generate updated Terraform configuration
