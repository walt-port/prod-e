# VPC and Networking Components

## Overview

This document describes the VPC and networking infrastructure components created for the project.

## Architecture

The networking architecture consists of:

- A VPC with CIDR range `10.0.0.0/16`
- Public subnet with CIDR `10.0.1.0/24` in us-west-2a
- Private subnet with CIDR `10.0.2.0/24` in us-west-2a
- Internet Gateway for public internet access
- Route tables for public and private subnets

## Components

### VPC

The Virtual Private Cloud (VPC) serves as the network foundation for all AWS resources. It's configured with:

- DNS support enabled
- DNS hostnames enabled
- Proper tagging for resource management

### Subnets

#### Public Subnet

- Located in us-west-2a
- CIDR block: `10.0.1.0/24`
- Auto-assigns public IP addresses to instances
- Connected to an Internet Gateway for direct internet access

#### Private Subnet

- Located in us-west-2a
- CIDR block: `10.0.2.0/24`
- No public IP addresses assigned to instances
- No direct internet access (intentional)

### Internet Gateway

An Internet Gateway is attached to the VPC to allow resources in the public subnet to communicate with the internet.

### Route Tables

#### Public Route Table

- Associated with the public subnet
- Contains a route to the Internet Gateway for all internet-bound traffic (0.0.0.0/0)

#### Private Route Table

- Associated with the private subnet
- Contains only local routes within the VPC
- No routes to the internet

## Future Enhancements

The current design uses a single availability zone (us-west-2a) for simplicity. Future enhancements will include:

- Adding public and private subnets in us-west-2b and us-west-2c
- Implementing NAT Gateways for private subnet internet access
- Enhancing route tables for multi-AZ routing
