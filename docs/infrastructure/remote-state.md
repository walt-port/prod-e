# Remote State Backend

## Overview

This document describes the remote state backend setup for the Production Experience Showcase project. The project uses AWS S3 as a remote backend for Terraform state with DynamoDB for state locking to provide centralized storage, prevent concurrent modifications, and enable team collaboration.

## Table of Contents

- [Infrastructure](#infrastructure)
- [Configuration](#configuration)
- [IAM Permissions](#iam-permissions)
- [GitHub Actions Integration](#github-actions-integration)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Related Documentation](#related-documentation)

## Infrastructure

The following AWS resources are used for the remote state backend:

- **S3 Bucket**: `prod-e-terraform-state`

  - Stores the Terraform state file
  - Versioning enabled for history and recovery
  - Server-side encryption enabled with AES256

- **DynamoDB Table**: `prod-e-terraform-lock`
  - Provides state locking to prevent concurrent modifications
  - Uses `LockID` as the primary key
  - Pay-per-request billing mode

## Configuration

The remote state backend is configured in two places:

1. **cdktf.json**: Defines the backend configuration for local development

   ```json
   "terraformBackend": {
     "s3": {
       "bucket": "prod-e-terraform-state",
       "key": "terraform.tfstate",
       "region": "us-west-2",
       "encrypt": true,
       "dynamodb_table": "prod-e-terraform-lock"
     }
   }
   ```

2. **main.ts**: Configures the S3 backend in the TerraformStack
   ```typescript
   new S3Backend(this, {
     bucket: 'prod-e-terraform-state',
     key: 'terraform.tfstate',
     region: 'us-west-2',
     encrypt: true,
     dynamodb_table: 'prod-e-terraform-lock',
   });
   ```

## IAM Permissions

A specific IAM policy named `TerraformStateAccess` has been created to grant the necessary permissions for accessing the remote state:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::prod-e-terraform-state", "arn:aws:s3:::prod-e-terraform-state/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
      "Resource": "arn:aws:dynamodb:us-west-2:*:table/prod-e-terraform-lock"
    }
  ]
}
```

This policy should be attached to:

- IAM users/roles used for local development
- The IAM role used by GitHub Actions for CI/CD

## GitHub Actions Integration

The GitHub Actions workflow automatically uses the remote state backend as configured in the code. No additional configuration is needed in the workflow file.

## Troubleshooting

### State Lock Issues

If a deployment fails and the state lock is not released, you can manually remove it with:

```bash
$ aws dynamodb delete-item \
  --table-name prod-e-terraform-lock \
  --key '{"LockID": {"S": "prod-e-terraform-state/terraform.tfstate-md5"}}' \
  --region us-west-2
```

### State Recovery

If the state file becomes corrupted, you can recover a previous version from the S3 bucket using the AWS Console or CLI:

```bash
$ aws s3api list-object-versions \
  --bucket prod-e-terraform-state \
  --prefix terraform.tfstate

# Then restore a specific version
$ aws s3api get-object \
  --bucket prod-e-terraform-state \
  --key terraform.tfstate \
  --version-id VERSION_ID \
  terraform.tfstate.backup
```

## Security Considerations

1. **Access Control**: Only authorized users should have access to the state backend
2. **Encryption**: All state data is encrypted at rest
3. **Versioning**: Enables recovery from accidental or malicious changes
4. **Least Privilege**: IAM policy follows the principle of least privilege

## Related Documentation

- [Infrastructure Overview](./overview.md)
- [CI/CD Pipeline](./ci-cd.md)

---

**Last Updated**: 2025-03-15
**Version**: 1.0
