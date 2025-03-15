# Scripts

This directory contains utility scripts for managing, monitoring, and maintaining the Production Experience Showcase infrastructure.

## Overview

These scripts provide automation for common DevOps tasks such as checking resource status, building and deploying container images, tearing down infrastructure, and creating Lambda function packages.

## Available Scripts

| Script                                     | Purpose                                              | Language |
| ------------------------------------------ | ---------------------------------------------------- | -------- |
| [build-and-push.sh](#build-and-push)       | Build and push Docker images to ECR                  | Bash     |
| [create-lambda-zip.js](#create-lambda-zip) | Create deployment package for Lambda functions       | Node.js  |
| [resource_check.sh](#resource-check)       | Check status of all AWS resources                    | Bash     |
| [teardown.py](#teardown)                   | Clean up all AWS resources with fine-grained control | Python   |

## Script Details

### <a name="build-and-push"></a>build-and-push.sh

Builds and pushes Docker images to Amazon ECR repositories.

**Features:**

- Automatic ECR repository creation if it doesn't exist
- AWS account detection and authentication
- Proper tagging and versioning

**Usage:**

```bash
# Basic usage (builds and pushes backend image)
./scripts/build-and-push.sh

# Build specific image (backend, prometheus, or grafana)
./scripts/build-and-push.sh --image backend
./scripts/build-and-push.sh --image prometheus
./scripts/build-and-push.sh --image grafana

# Build all images
./scripts/build-and-push.sh --all
```

**Requirements:**

- Docker installed and running
- AWS CLI configured with appropriate credentials
- Appropriate Dockerfiles present in respective directories

### <a name="create-lambda-zip"></a>create-lambda-zip.js

Creates a ZIP deployment package for AWS Lambda functions.

**Features:**

- Packages Lambda function code into a ZIP file
- Creates proper directory structure for Lambda deployment
- Works with Node.js Lambda functions

**Usage:**

```bash
# Create Lambda ZIP package
node scripts/create-lambda-zip.js
```

**Requirements:**

- Node.js installed
- JSZip package installed (`npm install jszip`)

### <a name="resource-check"></a>resource_check.sh

Provides comprehensive status checks for all AWS resources used in the project.

**Features:**

- Color-coded output for easy status identification
- Checks for VPC, subnets, security groups, route tables
- Checks RDS database instances
- Checks ECS clusters, services, and tasks
- Checks ECR repositories
- Checks Terraform state (S3 and DynamoDB)
- Checks monitoring components (Prometheus, Grafana)
- Checks Lambda functions and event rules
- Checks EFS file systems and mount targets

**Usage:**

```bash
# Check all resources
./scripts/resource_check.sh

# Check specific resource category
./scripts/resource_check.sh --vpc
./scripts/resource_check.sh --ecs
./scripts/resource_check.sh --monitoring
```

**Requirements:**

- AWS CLI configured with appropriate credentials
- `jq` installed for JSON parsing

### <a name="teardown"></a>teardown.py

Safely and methodically destroys AWS resources with detailed control and visibility.

**Features:**

- Dry-run mode to preview resources that would be deleted
- Confirmation step to prevent accidental deletion
- Handles dependencies correctly by deleting in the proper order
- Detailed output during the process

**Usage:**

```bash
# Show resources that would be deleted (dry run)
python scripts/teardown.py --dry-run

# Delete resources with confirmation
python scripts/teardown.py

# Target specific region or project
python scripts/teardown.py --region us-west-2 --project-tag prod-e
```

**Requirements:**

- Python 3.6 or higher
- AWS SDK for Python (boto3): `pip install boto3`
- AWS credentials configured

## Best Practices

When using these scripts, follow these best practices:

1. **Always run in a test environment first** before using in production
2. **Review actions** before confirming destructive operations
3. **Back up important data** before making infrastructure changes
4. **Keep AWS credentials secure** and use roles with appropriate permissions
5. **Use version control** to track changes to scripts

## Contributing

When adding new scripts to this directory:

1. Use descriptive names that reflect the script's purpose
2. Add proper documentation in the script header
3. Make scripts executable with `chmod +x`
4. Update this README with information about the new script
5. Consider adding error handling and logging to ensure reliability
6. Add a section in this README following the established format

## Related Documentation

- [Infrastructure Documentation](../docs/infrastructure/README.md)
- [Deployment Guide](../docs/guides/deployment-guide.md)
- [Monitoring Documentation](../docs/monitoring/README.md)
