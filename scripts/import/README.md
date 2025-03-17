# AWS Resource Import Script

A utility script for detecting existing AWS resources and generating Terraform import commands.

## Overview

This script scans your AWS account for resources and generates Terraform import commands to help you bring existing infrastructure under Terraform management. It's particularly useful for migrating manually created resources to infrastructure as code.

## Features

- Detects various AWS resources:
  - VPCs and associated resources
  - RDS instances
  - Application Load Balancers
  - ECS Clusters
- Generates Terraform import commands
- Configurable output format
- Region and stack filtering

## Prerequisites

- Node.js 14 or higher
- AWS CLI configured with appropriate credentials
- AWS SDK for JavaScript

## Installation

1. Clone the repository
2. Navigate to the script directory:
   ```
   cd scripts/import
   ```
3. Install dependencies:
   ```
   npm install
   ```

## Usage

Run the script with the following command:

```
node import.js [options]
```

### Options

- `--region <region>`: AWS region to scan (default: us-west-2)
- `--stack <stack-name>`: Filter resources by stack name
- `--output <output-dir>`: Directory to save import commands (default: ./import-commands)

### Example

```
node import.js --region us-east-1 --stack production --output ./my-imports
```

## Output

The script generates a file containing Terraform import commands that can be executed to import resources into your Terraform state. Example output:

```
terraform import aws_vpc.main vpc-0123456789abcdef0
terraform import aws_rds_cluster.database arn:aws:rds:us-west-2:123456789012:cluster:my-database
terraform import aws_lb.frontend arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-lb/0123456789abcdef
```

## Testing

Run the tests using Jest:

```
npm test
```

## Documentation

For more detailed information, see the [full documentation](../../docs/scripts/import.md).
