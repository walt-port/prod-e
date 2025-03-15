#!/bin/bash

# AWS Resource Cleanup Script for Production Experience Showcase
# This script identifies and optionally removes unused resources to reduce costs

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
PROJECT_TAG="prod-e"
DRY_RUN=true
DAYS_OLD=7

# Print usage information
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Clean up unused AWS resources for the Production Experience Showcase"
  echo ""
  echo "Options:"
  echo "  -r, --region REGION      AWS region (default: us-west-2)"
  echo "  -p, --project TAG        Project tag to identify resources (default: prod-e)"
  echo "  -d, --days NUMBER        Age in days for resource cleanup (default: 7)"
  echo "  -f, --force              Execute actual deletions (without this, runs in dry-run mode)"
  echo "  -h, --help               Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0                       List unused resources (dry run)"
  echo "  $0 --force               Clean up unused resources"
  echo "  $0 --days 14 --force     Clean up resources older than 14 days"
}

# Process command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--region)
      AWS_REGION="$2"
      shift 2
      ;;
    -p|--project)
      PROJECT_TAG="$2"
      shift 2
      ;;
    -d|--days)
      DAYS_OLD="$2"
      shift 2
      ;;
    -f|--force)
      DRY_RUN=false
      shift
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

# Calculate the cutoff date
CUTOFF_DATE=$(date -d "$DAYS_OLD days ago" +%Y-%m-%d)

echo -e "${BLUE}=== AWS Resource Cleanup Tool ===${NC}"
echo -e "Project: $PROJECT_TAG"
echo -e "Region: $AWS_REGION"
echo -e "Mode: $(if $DRY_RUN; then echo "Dry Run (no deletions)"; else echo "Force (will delete resources)"; fi)"
echo -e "Age threshold: $DAYS_OLD days (before $CUTOFF_DATE)"
echo ""

# Check AWS CLI configuration
echo -e "${BLUE}Checking AWS CLI configuration...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo -e "${RED}Error: AWS CLI is not configured correctly${NC}"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo -e "${GREEN}AWS CLI configured for account: $ACCOUNT_ID${NC}"

# Function to confirm deletions
confirm_action() {
  if $DRY_RUN; then
    return 1  # Skip in dry run mode
  fi

  read -p "Proceed with deletion? (y/n): " CONFIRM
  if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    return 1
  fi
  return 0
}

# Clean up old ECR images
cleanup_ecr_images() {
  echo -e "\n${BLUE}Checking for old ECR images...${NC}"

  # List ECR repositories
  REPOS=$(aws ecr describe-repositories --region $AWS_REGION --query "repositories[?contains(repositoryName, '$PROJECT_TAG')].[repositoryName]" --output text)

  if [ -z "$REPOS" ]; then
    echo -e "${YELLOW}No ECR repositories found for project $PROJECT_TAG${NC}"
    return
  fi

  echo -e "Found $(echo "$REPOS" | wc -l) ECR repositories:"

  for repo in $REPOS; do
    echo -e "\n${BLUE}Scanning repository: $repo${NC}"

    # Get images older than cutoff date, excluding the latest image
    LATEST_DIGEST=$(aws ecr describe-images --repository-name "$repo" --query "sort_by(imageDetails, &imagePushedAt)[-1].imageDigest" --output text --region $AWS_REGION)

    # Find old images, excluding the latest
    OLD_IMAGES=$(aws ecr describe-images --repository-name "$repo" --region $AWS_REGION \
      --query "imageDetails[?imagePushedAt<='$CUTOFF_DATE' && imageDigest!='$LATEST_DIGEST'].[imageDigest,imageTags[0],imagePushedAt]" --output text)

    if [ -z "$OLD_IMAGES" ]; then
      echo -e "${GREEN}No old images found in $repo${NC}"
      continue
    fi

    # Count and list old images
    OLD_IMAGE_COUNT=$(echo "$OLD_IMAGES" | wc -l)
    echo -e "${YELLOW}Found $OLD_IMAGE_COUNT old image(s) in $repo:${NC}"

    echo "$OLD_IMAGES" | while read -r digest tag date; do
      tag=${tag:-"<untagged>"}
      echo -e "  - Digest: ${digest:0:12}... | Tag: $tag | Date: $date"
    done

    if confirm_action; then
      echo -e "${BLUE}Deleting old images from $repo...${NC}"

      # Delete each old image
      echo "$OLD_IMAGES" | while read -r digest tag date; do
        echo -e "  Deleting image $digest (pushed at $date)..."
        aws ecr batch-delete-image --repository-name "$repo" --image-ids imageDigest="$digest" --region $AWS_REGION
      done

      echo -e "${GREEN}Deleted $OLD_IMAGE_COUNT old image(s) from $repo${NC}"
    else
      echo -e "${YELLOW}Skipping deletion of images from $repo${NC}"
    fi
  done
}

# Clean up unattached EBS volumes
cleanup_ebs_volumes() {
  echo -e "\n${BLUE}Checking for unattached EBS volumes...${NC}"

  # Find unattached volumes
  VOLUMES=$(aws ec2 describe-volumes --region $AWS_REGION \
    --filters "Name=status,Values=available" "Name=tag:Project,Values=$PROJECT_TAG" \
    --query "Volumes[?CreateTime<='$CUTOFF_DATE'].[VolumeId,Size,CreateTime,State]" --output text)

  if [ -z "$VOLUMES" ]; then
    echo -e "${GREEN}No unattached volumes found for project $PROJECT_TAG${NC}"
    return
  fi

  # Count and list unattached volumes
  VOLUME_COUNT=$(echo "$VOLUMES" | wc -l)
  echo -e "${YELLOW}Found $VOLUME_COUNT unattached volume(s):${NC}"

  echo "$VOLUMES" | while read -r id size date state; do
    echo -e "  - $id | ${size}GB | Created: $date | State: $state"
  done

  if confirm_action; then
    echo -e "${BLUE}Deleting unattached volumes...${NC}"

    # Delete each volume
    echo "$VOLUMES" | while read -r id size date state; do
      echo -e "  Deleting volume $id..."
      aws ec2 delete-volume --volume-id "$id" --region $AWS_REGION
    done

    echo -e "${GREEN}Deleted $VOLUME_COUNT unattached volume(s)${NC}"
  else
    echo -e "${YELLOW}Skipping deletion of unattached volumes${NC}"
  fi
}

# Clean up old EBS snapshots
cleanup_ebs_snapshots() {
  echo -e "\n${BLUE}Checking for old EBS snapshots...${NC}"

  # Find old snapshots
  SNAPSHOTS=$(aws ec2 describe-snapshots --owner-ids "$ACCOUNT_ID" --region $AWS_REGION \
    --filters "Name=tag:Project,Values=$PROJECT_TAG" \
    --query "Snapshots[?StartTime<='$CUTOFF_DATE'].[SnapshotId,VolumeId,StartTime,Description]" --output text)

  if [ -z "$SNAPSHOTS" ]; then
    echo -e "${GREEN}No old snapshots found for project $PROJECT_TAG${NC}"
    return
  fi

  # Count and list old snapshots
  SNAPSHOT_COUNT=$(echo "$SNAPSHOTS" | wc -l)
  echo -e "${YELLOW}Found $SNAPSHOT_COUNT old snapshot(s):${NC}"

  echo "$SNAPSHOTS" | while read -r id vol_id date desc; do
    echo -e "  - $id | Volume: $vol_id | Created: $date | $desc"
  done

  if confirm_action; then
    echo -e "${BLUE}Deleting old snapshots...${NC}"

    # Delete each snapshot
    echo "$SNAPSHOTS" | while read -r id vol_id date desc; do
      echo -e "  Deleting snapshot $id..."
      aws ec2 delete-snapshot --snapshot-id "$id" --region $AWS_REGION
    done

    echo -e "${GREEN}Deleted $SNAPSHOT_COUNT old snapshot(s)${NC}"
  else
    echo -e "${YELLOW}Skipping deletion of old snapshots${NC}"
  fi
}

# Clean up old RDS snapshots
cleanup_rds_snapshots() {
  echo -e "\n${BLUE}Checking for old RDS snapshots...${NC}"

  # Find old manual snapshots
  SNAPSHOTS=$(aws rds describe-db-snapshots --snapshot-type manual --region $AWS_REGION \
    --query "DBSnapshots[?SnapshotCreateTime<='$CUTOFF_DATE' && contains(DBSnapshotIdentifier, '$PROJECT_TAG')].[DBSnapshotIdentifier,DBInstanceIdentifier,SnapshotCreateTime]" --output text)

  if [ -z "$SNAPSHOTS" ]; then
    echo -e "${GREEN}No old RDS snapshots found for project $PROJECT_TAG${NC}"
    return
  fi

  # Count and list old snapshots
  SNAPSHOT_COUNT=$(echo "$SNAPSHOTS" | wc -l)
  echo -e "${YELLOW}Found $SNAPSHOT_COUNT old RDS snapshot(s):${NC}"

  echo "$SNAPSHOTS" | while read -r id db_id date; do
    echo -e "  - $id | DB: $db_id | Created: $date"
  done

  if confirm_action; then
    echo -e "${BLUE}Deleting old RDS snapshots...${NC}"

    # Delete each snapshot
    echo "$SNAPSHOTS" | while read -r id db_id date; do
      echo -e "  Deleting RDS snapshot $id..."
      aws rds delete-db-snapshot --db-snapshot-identifier "$id" --region $AWS_REGION
    done

    echo -e "${GREEN}Deleted $SNAPSHOT_COUNT old RDS snapshot(s)${NC}"
  else
    echo -e "${YELLOW}Skipping deletion of old RDS snapshots${NC}"
  fi
}

# Clean up old CloudWatch logs
cleanup_cloudwatch_logs() {
  echo -e "\n${BLUE}Checking for old CloudWatch log groups...${NC}"

  # Find log groups with retention not set
  LOG_GROUPS=$(aws logs describe-log-groups --region $AWS_REGION \
    --query "logGroups[?!retentionInDays && contains(logGroupName, '$PROJECT_TAG')].[logGroupName,storedBytes]" --output text)

  if [ -z "$LOG_GROUPS" ]; then
    echo -e "${GREEN}No log groups without retention policy found for project $PROJECT_TAG${NC}"
    return
  fi

  # Count and list log groups
  LOG_GROUP_COUNT=$(echo "$LOG_GROUPS" | wc -l)
  echo -e "${YELLOW}Found $LOG_GROUP_COUNT log group(s) without retention policy:${NC}"

  echo "$LOG_GROUPS" | while read -r name size; do
    size_mb=$(echo "scale=2; $size/1024/1024" | bc)
    echo -e "  - $name (${size_mb}MB)"
  done

  if confirm_action; then
    echo -e "${BLUE}Setting retention policy on log groups...${NC}"

    # Set retention on each log group
    echo "$LOG_GROUPS" | while read -r name size; do
      echo -e "  Setting 30-day retention on $name..."
      aws logs put-retention-policy --log-group-name "$name" --retention-in-days 30 --region $AWS_REGION
    done

    echo -e "${GREEN}Set retention policy on $LOG_GROUP_COUNT log group(s)${NC}"
  else
    echo -e "${YELLOW}Skipping setting retention policy on log groups${NC}"
  fi
}

# Clean up old Lambda versions
cleanup_lambda_versions() {
  echo -e "\n${BLUE}Checking for old Lambda function versions...${NC}"

  # Find Lambda functions for the project
  FUNCTIONS=$(aws lambda list-functions --region $AWS_REGION \
    --query "Functions[?contains(FunctionName, '$PROJECT_TAG')].[FunctionName]" --output text)

  if [ -z "$FUNCTIONS" ]; then
    echo -e "${GREEN}No Lambda functions found for project $PROJECT_TAG${NC}"
    return
  fi

  echo -e "Found $(echo "$FUNCTIONS" | wc -l) Lambda functions:"

  for func in $FUNCTIONS; do
    echo -e "\n${BLUE}Checking versions for function: $func${NC}"

    # Get the current version (to keep)
    CURRENT_VERSION=$(aws lambda get-function --function-name "$func" --region $AWS_REGION \
      --query "Configuration.Version" --output text)

    # List all versions
    VERSIONS=$(aws lambda list-versions-by-function --function-name "$func" --region $AWS_REGION \
      --query "Versions[?Version!='$CURRENT_VERSION' && Version!='$LATEST'].[Version,LastModified]" --output text)

    if [ -z "$VERSIONS" ]; then
      echo -e "${GREEN}No old versions found for $func${NC}"
      continue
    fi

    # Count and list old versions
    VERSION_COUNT=$(echo "$VERSIONS" | wc -l)
    echo -e "${YELLOW}Found $VERSION_COUNT old version(s) for $func:${NC}"

    echo "$VERSIONS" | while read -r version date; do
      echo -e "  - Version: $version | Last modified: $date"
    done

    if confirm_action; then
      echo -e "${BLUE}Deleting old versions for $func...${NC}"

      # Delete each old version
      echo "$VERSIONS" | while read -r version date; do
        echo -e "  Deleting version $version..."
        aws lambda delete-function --function-name "$func" --qualifier "$version" --region $AWS_REGION
      done

      echo -e "${GREEN}Deleted $VERSION_COUNT old version(s) for $func${NC}"
    else
      echo -e "${YELLOW}Skipping deletion of old Lambda versions for $func${NC}"
    fi
  done
}

# Main execution
if $DRY_RUN; then
  echo -e "${YELLOW}Running in DRY RUN mode - no resources will be modified or deleted${NC}"
  echo -e "${YELLOW}Use the --force flag to perform actual cleanup${NC}"
else
  echo -e "${RED}WARNING: Running in FORCE mode - resources will be deleted!${NC}"
  echo -e "${RED}Make sure you have reviewed the resources before confirming deletion${NC}"

  # Global confirmation for force mode
  read -p "Are you sure you want to proceed with cleanup? (y/n): " CONFIRM
  if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${BLUE}Cleanup cancelled${NC}"
    exit 0
  fi
fi

# Run all cleanup functions
cleanup_ecr_images
cleanup_ebs_volumes
cleanup_ebs_snapshots
cleanup_rds_snapshots
cleanup_cloudwatch_logs
cleanup_lambda_versions

echo -e "\n${BLUE}=== Resource Cleanup Summary ===${NC}"
if $DRY_RUN; then
  echo -e "${YELLOW}Dry run completed. Run with --force to perform actual cleanup.${NC}"
else
  echo -e "${GREEN}Cleanup operations completed.${NC}"
fi

exit 0
