# Scripts Documentation

This directory contains various scripts used for managing the Production Experience application infrastructure and services.

## Directory Structure

- `monitoring/` - Scripts for monitoring and checking infrastructure health

  - `monitor-health.sh` - Continuously monitors the health of all services
  - `resource_check.sh` - Performs comprehensive checks of AWS resources

- `deployment/` - Scripts related to deployment processes

  - `build-and-push.sh` - Builds Docker images and pushes to ECR
  - `create-lambda-zip.js` - Creates deployment zip files for Lambda functions
  - `rollback.sh` - Rolls back to previous deployment versions

- `maintenance/` - Scripts for infrastructure maintenance

  - `cleanup-resources.sh` - Cleans up unused AWS resources
  - `teardown.py` - Tears down infrastructure components

- `backup/` - Scripts for data backup operations

  - `backup-database.sh` - Performs database backups

## Documentation

Detailed documentation for each script, including usage examples and parameters, can be found in the main project documentation directory:

- **[Scripts Documentation](../docs/scripts/README.md)**

See the scripts documentation in the `../docs/scripts/README.md` file for detailed usage instructions.

## Contribution
