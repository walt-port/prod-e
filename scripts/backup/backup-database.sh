#!/bin/bash

# Database Backup Script for Production Experience Showcase
# This script creates a snapshot of the RDS database and exports it to S3

# Exit on error
set -e

# Set AWS region
AWS_REGION="us-west-2"

# ANSI color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
S3_BACKUP_BUCKET="prod-e-database-backups"
EXPORT_TASK_ROLE="prod-e-rds-export-role"
MAX_SNAPSHOTS_TO_KEEP=7

# Print usage information
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Create a backup of the RDS database for the Production Experience Showcase"
  echo ""
  echo "Options:"
  echo "  -d, --db-instance ID   RDS DB instance identifier"
  echo "  -b, --bucket NAME      S3 bucket for backups (default: $S3_BACKUP_BUCKET)"
  echo "  -k, --keep NUMBER      Maximum number of snapshots to retain (default: $MAX_SNAPSHOTS_TO_KEEP)"
  echo "  -p, --prefix PREFIX    Prefix for snapshot names (default: prod-e)"
  echo "  -h, --help             Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --db-instance prod-e-db        Create backup with default settings"
  echo "  $0 --db-instance prod-e-db --keep 5   Keep only 5 most recent snapshots"
}

# Process command line arguments
DB_INSTANCE=""
SNAPSHOT_PREFIX="prod-e"

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--db-instance)
      DB_INSTANCE="$2"
      shift 2
      ;;
    -b|--bucket)
      S3_BACKUP_BUCKET="$2"
      shift 2
      ;;
    -k|--keep)
      MAX_SNAPSHOTS_TO_KEEP="$2"
      shift 2
      ;;
    -p|--prefix)
      SNAPSHOT_PREFIX="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$DB_INSTANCE" ]; then
  echo -e "${RED}Error: DB instance identifier is required${NC}"
  usage
  exit 1
fi

# Check if the DB instance exists
echo -e "${BLUE}Checking if DB instance $DB_INSTANCE exists...${NC}"
DB_CHECK=$(aws rds describe-db-instances --db-instance-identifier "$DB_INSTANCE" --region "$AWS_REGION" 2>&1) || {
  echo -e "${RED}Error: DB instance $DB_INSTANCE not found${NC}"
  exit 1
}

# Check if the S3 bucket exists, create if it doesn't
echo -e "${BLUE}Checking if S3 bucket $S3_BACKUP_BUCKET exists...${NC}"
if ! aws s3api head-bucket --bucket "$S3_BACKUP_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
  echo -e "${YELLOW}S3 bucket $S3_BACKUP_BUCKET doesn't exist, creating it...${NC}"
  aws s3api create-bucket \
    --bucket "$S3_BACKUP_BUCKET" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"

  # Configure bucket for backup storage
  aws s3api put-bucket-lifecycle-configuration \
    --bucket "$S3_BACKUP_BUCKET" \
    --lifecycle-configuration '{
      "Rules": [
        {
          "ID": "Move-to-IA-and-Glacier",
          "Status": "Enabled",
          "Prefix": "",
          "Transitions": [
            {
              "Days": 30,
              "StorageClass": "STANDARD_IA"
            },
            {
              "Days": 90,
              "StorageClass": "GLACIER"
            }
          ],
          "Expiration": {
            "Days": 365
          }
        }
      ]
    }'

  echo -e "${GREEN}S3 bucket created and configured${NC}"
fi

# Generate a snapshot ID
SNAPSHOT_ID="${SNAPSHOT_PREFIX}-backup-${TIMESTAMP}"
echo -e "${BLUE}Creating snapshot $SNAPSHOT_ID...${NC}"

# Create DB snapshot
aws rds create-db-snapshot \
  --db-instance-identifier "$DB_INSTANCE" \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --region "$AWS_REGION" \
  --tags Key=Project,Value=prod-e Key=CreatedBy,Value=backup-script

echo -e "${YELLOW}Waiting for snapshot to complete...${NC}"
aws rds wait db-snapshot-available \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --region "$AWS_REGION"

echo -e "${GREEN}Snapshot $SNAPSHOT_ID created successfully${NC}"

# Export snapshot to S3
echo -e "${BLUE}Exporting snapshot to S3...${NC}"
EXPORT_TASK_ID="${SNAPSHOT_ID}-export"

aws rds start-export-task \
  --export-task-identifier "$EXPORT_TASK_ID" \
  --source-arn "$(aws rds describe-db-snapshots --db-snapshot-identifier "$SNAPSHOT_ID" --region "$AWS_REGION" --query 'DBSnapshots[0].DBSnapshotArn' --output text)" \
  --s3-bucket-name "$S3_BACKUP_BUCKET" \
  --iam-role-arn "$(aws iam get-role --role-name "$EXPORT_TASK_ROLE" --query 'Role.Arn' --output text)" \
  --kms-key-id "alias/aws/rds" \
  --s3-prefix "exports/" \
  --region "$AWS_REGION"

echo -e "${YELLOW}Export task $EXPORT_TASK_ID started. This may take some time to complete.${NC}"
echo -e "${YELLOW}Monitor progress with: aws rds describe-export-tasks --export-task-identifier $EXPORT_TASK_ID --region $AWS_REGION${NC}"

# Clean up old snapshots
echo -e "${BLUE}Cleaning up old snapshots...${NC}"

# Get list of snapshots for this DB instance with our prefix
SNAPSHOTS=$(aws rds describe-db-snapshots \
  --db-instance-identifier "$DB_INSTANCE" \
  --region "$AWS_REGION" \
  --query "sort_by(DBSnapshots[?starts_with(DBSnapshotIdentifier, '${SNAPSHOT_PREFIX}-backup-')], &SnapshotCreateTime)" \
  --output text \
  --query "DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]")

# Count snapshots
SNAPSHOT_COUNT=$(echo "$SNAPSHOTS" | wc -l)

# If we have more snapshots than we want to keep, delete the oldest ones
if [ "$SNAPSHOT_COUNT" -gt "$MAX_SNAPSHOTS_TO_KEEP" ]; then
  # Calculate how many to delete
  TO_DELETE=$((SNAPSHOT_COUNT - MAX_SNAPSHOTS_TO_KEEP))
  echo -e "${YELLOW}Found $SNAPSHOT_COUNT snapshots, removing $TO_DELETE oldest...${NC}"

  # Get the oldest snapshots
  OLD_SNAPSHOTS=$(echo "$SNAPSHOTS" | head -n $TO_DELETE | awk '{print $1}')

  # Delete each old snapshot
  for OLD_SNAPSHOT in $OLD_SNAPSHOTS; do
    echo -e "${YELLOW}Deleting old snapshot: $OLD_SNAPSHOT${NC}"
    aws rds delete-db-snapshot \
      --db-snapshot-identifier "$OLD_SNAPSHOT" \
      --region "$AWS_REGION"
  done

  echo -e "${GREEN}Deleted $TO_DELETE old snapshots${NC}"
else
  echo -e "${GREEN}No cleanup needed, only $SNAPSHOT_COUNT snapshots exist (keeping $MAX_SNAPSHOTS_TO_KEEP)${NC}"
fi

echo -e "${GREEN}Database backup process completed successfully${NC}"
echo -e "${BLUE}Snapshot: $SNAPSHOT_ID${NC}"
echo -e "${BLUE}Export task: $EXPORT_TASK_ID${NC}"
echo -e "${BLUE}S3 location: s3://$S3_BACKUP_BUCKET/exports/${NC}"

exit 0
