# Scripts for Production Experience Showcase

This directory contains utility scripts for managing and monitoring the Production Experience Showcase infrastructure.

## Available Scripts

### `resource_check.sh`

A comprehensive resource checking utility that provides status information about all AWS resources used in the project.

**Features:**

- Checks VPC and networking components
- Checks RDS database instances and subnet groups
- Checks ECS cluster, services, and tasks
- Checks Application Load Balancer and target groups
- Checks ECR repositories and container images
- Checks Terraform state resources (S3 bucket and DynamoDB table)
- Checks Prometheus monitoring service
- Color-coded output for easy status identification

**Usage:**

```bash
# Make sure the script is executable
chmod +x scripts/resource_check.sh

# Run the script
./scripts/resource_check.sh
```

**Requirements:**

- AWS CLI configured with appropriate credentials
- `jq` for JSON parsing (script will check and prompt for installation if missing)

## Adding New Scripts

When adding new scripts to this directory:

1. Use descriptive names that reflect the script's purpose
2. Add proper documentation in the script header
3. Make scripts executable with `chmod +x`
4. Update this README with information about the new script
5. Consider adding error handling and logging to ensure reliability

## Teardown Script

The `teardown.py` script is designed to help tear down AWS infrastructure resources created by this project. It offers an alternative to the `npm run destroy` command by providing more granular control and detailed output during the teardown process.

### Prerequisites

Before using the script, ensure you have the following:

1. Python 3.6 or higher installed
2. AWS SDK for Python (boto3) installed:
   ```
   pip install boto3
   ```
3. AWS credentials configured (via AWS CLI, environment variables, or credentials file)

### Installation

No special installation is needed. Just ensure the script is executable:

```bash
chmod +x teardown.py
```

### Usage

Basic usage:

```bash
python teardown.py
```

With options:

```bash
python teardown.py --dry-run --region us-west-2 --project-tag prod-e
```

### Options

- `--dry-run`: Run in dry-run mode (list resources without deleting them)
- `--region`: Specify the AWS region (default: us-west-2)
- `--project-tag`: Specify the project tag value to identify resources (default: prod-e)

### How It Works

The script works by:

1. Identifying all resources with the specified project tag
2. Showing you what resources will be deleted
3. Asking for confirmation before proceeding with deletion
4. Deleting resources in the correct order (reverse dependency order)

### Resource Types Handled

The script can delete the following types of resources:

- ECS clusters, services, and task definitions
- Application Load Balancers, listeners, and target groups
- RDS instances and subnet groups
- VPC resources (security groups, route tables, internet gateways, subnets)
- IAM roles and policies

### Example Output

```
AWS Region: us-west-2
Project Tag: prod-e
Dry Run: Yes

DRY RUN MODE: Resources will be identified but not deleted

=== Identifying Resources ===

Searching for ECS services...
Found cluster: prod-e-cluster
  Found service: prod-e-service

Searching for ECS task definitions...
Found task definition: arn:aws:ecs:us-west-2:123456789012:task-definition/prod-e-task:1

Searching for load balancers...
Found load balancer: application-load-balancer (arn:aws:elasticloadbalancing:...)
  Found listener: arn:aws:elasticloadbalancing:...
    Found rule: arn:aws:elasticloadbalancing:...
Found target group: ecs-target-group (arn:aws:elasticloadbalancing:...)

...

Are you sure you want to delete these resources? This cannot be undone. (yes/no):
```

### Comparison with `npm run destroy`

While `npm run destroy` is simpler to use, this script offers:

- More detailed output and visibility into what's being deleted
- Confirmation step before deletion begins
- Useful for troubleshooting when standard destroy fails
- Can identify resources that might have been created outside of Terraform

## Future Scripts

Additional scripts will be added to this directory as the project evolves.
