# Import Script

## Overview

The Import Script is a utility designed to detect existing AWS resources and generate import commands for Terraform/CDKTF. This script streamlines the process of integrating pre-existing infrastructure with Infrastructure as Code (IaC) practices, allowing for easier management and version control of cloud resources.

## Functionality

The script scans for common AWS resources such as:

- VPC and related network components
- RDS database instances
- Application Load Balancers
- ECS Clusters

For each detected resource, the script generates the appropriate Terraform import commands to bring these resources under Terraform's management.

## Prerequisites

- Node.js (v14+)
- AWS SDK credentials configured
- Appropriate AWS permissions to list resources

## Installation

```bash
cd scripts/import
npm install
```

## Usage

```bash
node import.js [options]
```

### Command Line Options

- `--ci`: Run in CI mode (non-interactive)
- `--region <region>`: AWS region to search for resources (default: us-west-2)
- `--stack <name>`: Stack name prefix for resources
- `--output <directory>`: Directory to output import commands (default: ./import-commands)

## Output

The script generates a shell script containing all the necessary Terraform import commands. This script can be executed to import all detected resources into your Terraform state.

Example output:

```bash
#!/bin/bash
# Generated import commands
terraform import aws_vpc.main vpc-12345678
terraform import aws_rds_cluster.database arn:aws:rds:us-west-2:123456789012:cluster:prod-database
# ... additional import commands
```

## Error Handling

The script includes comprehensive error handling for:

- AWS API failures
- Resource detection issues
- File system operations

Errors are logged with appropriate context to assist in troubleshooting.

## Integration with CI/CD

When used with the `--ci` flag, the script operates in a non-interactive mode suitable for integration with CI/CD pipelines. In this mode, it automatically generates import commands without prompting for user input.

## Security Considerations

- The script requires AWS credentials with permissions to list resources
- No modifications are made to AWS resources
- Generated import commands only include resource IDs, not sensitive data

## Related Documentation

- [Terraform Import Documentation](https://www.terraform.io/docs/cli/import/index.html)
- [CDKTF Documentation](https://developer.hashicorp.com/terraform/cdktf)
- [AWS Infrastructure Documentation](../infrastructure/aws.md)
