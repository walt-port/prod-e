# Resource Management in Prod-E Infrastructure

This document explains how Prod-E infrastructure handles existing AWS resources to prevent duplicate resource creation and efficiently manage infrastructure.

## Overview

The infrastructure code is designed to check for existing resources before attempting to create new ones. This prevents errors when running `cdktf apply` on infrastructure that has been partially or fully deployed already.

## Key Components

### 1. Environment Variables

- `SKIP_EXISTING_RESOURCES`: When set to "true", the infrastructure code will check for existing resources and skip creation of resources that already exist in AWS.

### 2. Resource Existence Checking

The stack provides a utility function `checkResourceExists` that:

- Checks if a resource with a specific name already exists in AWS
- Maintains a cache of resource existence results to avoid redundant checks
- Can be extended to use AWS API calls for more accurate checking

### 3. Conditional Resource Creation

Each construct (Networking, ALB, ECS, RDS, etc.) conditionally creates resources:

- The construct first checks if the resource exists
- If it exists, it references the existing resource instead of creating a new one
- If it doesn't exist, it creates a new resource

### 4. Import Script

The `import-resources.sh` script automates importing existing resources:

- Scans the AWS account for resources that match our patterns
- Generates Terraform import commands for existing resources
- Can automatically run the import commands
- Sets the `SKIP_EXISTING_RESOURCES` environment variable

## Usage

### Deploying When Resources May Already Exist

```bash
# Set environment variable to check for existing resources
export SKIP_EXISTING_RESOURCES=true

# Synthesize and apply the infrastructure
npx cdktf synth
npx cdktf apply
```

### Importing Existing Resources

```bash
# Run the import script
./infrastructure/scripts/import-resources.sh

# When prompted, confirm to run the import commands
# The script will:
# 1. Detect existing resources
# 2. Generate import commands
# 3. Run the import commands
# 4. Prepare for applying changes
```

### CI/CD Integration

The resource management is fully integrated with our CI/CD pipeline:

1. **Import Script CI Mode**: The import script can be run in CI mode with the `--ci` flag:

   ```bash
   ./infrastructure/scripts/import-resources.sh --ci
   ```

2. **GitHub Actions Workflow**:

   - Automatically creates Lambda function zip file
   - Runs the import script in CI mode before deployment
   - Sets `SKIP_EXISTING_RESOURCES=true` for the deployment step
   - Passes the same environment variable to resource checks

3. **Fully Automated Deployment**:
   - No manual intervention needed, even for existing resources
   - Lambda functions are kept up to date (e.g., runtime updates)
   - Deployment errors from duplicate resources are eliminated

### Resource Tagging

For better resource identification and management, all resources are tagged with:

- `Name`: A descriptive name of the resource
- `Project`: Set to "prod-e" to identify resources belonging to this project

## Implementation Details

### Core Infrastructure Stack (`ProdEStack`)

The main stack provides a `checkResourceExists` function to all constructs, allowing them to check for existing resources before creating new ones.

### Backup Construct Example

The Backup construct demonstrates how to conditionally create resources:

```typescript
// Check if bucket exists
const bucketExists = this.checkResourceExists('s3', 'prod-e-backups');

if (!bucketExists) {
  // Create new bucket
  this.bucket = new S3Bucket(this, 'backup-bucket', {...});
} else {
  // Reference existing bucket
  this.bucket = new S3Bucket(this, 'backup-bucket', {...});
}
```

### Lambda Runtime Updates

Even for existing resources, we can update certain properties. For example, the Lambda function runtime is updated to `nodejs20.x` regardless of whether the function exists:

```typescript
// Create or update the Lambda function
this.lambda = new LambdaFunction(this, 'backup-lambda', {
  functionName: 'prod-e-backup',
  runtime: 'nodejs20.x', // Using the updated runtime
  // other properties...
});
```

## Benefits

1. **Prevents Duplicate Resources**: Avoids creating duplicate AWS resources
2. **Handles Partial Deployments**: Gracefully continues deployment if some resources already exist
3. **Enables Incremental Updates**: Can update properties of existing resources
4. **Simplifies Operations**: No need to manually track which resources exist
5. **Reduces Deployment Errors**: Fewer deployment failures due to resource conflicts
6. **CI/CD Friendly**: Fully automated process works in CI/CD pipelines
