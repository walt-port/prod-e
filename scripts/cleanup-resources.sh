#!/bin/bash

# AWS Resource Cleanup Tool
# This script identifies and optionally removes old or unused AWS resources
# associated with the prod-e project.

set -e

# Configuration
PROJECT="prod-e"
AWS_REGION="us-west-2"
DAYS_OLD=7
FORCE_DELETE=false
DRY_RUN=true
VERBOSE=false

# Calculate date threshold for old resources (Unix timestamp in seconds)
# Replace bc with bash arithmetic
TODAY=$(date +%s)
# Instead of: THRESHOLD_DATE=$(echo "$TODAY - ($DAYS_OLD * 86400)" | bc)
THRESHOLD_DATE=$((TODAY - (DAYS_OLD * 86400)))
HUMAN_DATE=$(date -d "@$THRESHOLD_DATE" +%Y-%m-%d)

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --force) FORCE_DELETE=true; DRY_RUN=false ;;
    --days=*) DAYS_OLD="${1#*=}"
              # Recalculate with new days
              # THRESHOLD_DATE=$(echo "$TODAY - ($DAYS_OLD * 86400)" | bc)
              THRESHOLD_DATE=$((TODAY - (DAYS_OLD * 86400)))
              HUMAN_DATE=$(date -d "@$THRESHOLD_DATE" +%Y-%m-%d) ;;
    --region=*) AWS_REGION="${1#*=}" ;;
    --verbose) VERBOSE=true ;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --force         Perform actual deletion (default: dry run)"
      echo "  --days=N        Set age threshold to N days (default: 7)"
      echo "  --region=REGION Set AWS region (default: us-west-2)"
      echo "  --verbose       Display more detailed information"
      echo "  --help, -h      Display this help message"
      exit 0
      ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Display banner
echo "=== AWS Resource Cleanup Tool ==="
echo "Project: $PROJECT"
echo "Region: $AWS_REGION"
if [ "$DRY_RUN" = true ]; then
  echo "Mode: Dry Run (no deletions)"
else
  echo "Mode: FORCE DELETE"
fi
echo "Age threshold: $DAYS_OLD days (before $HUMAN_DATE)"
echo

# Verify AWS CLI configuration
echo "Checking AWS CLI configuration..."
AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Error: AWS CLI not configured properly. Please run 'aws configure'."
  exit 1
fi
echo "AWS CLI configured for account: $AWS_ACCOUNT"

# Warn if in dry run mode
if [ "$DRY_RUN" = true ]; then
  echo "Running in DRY RUN mode - no resources will be modified or deleted"
  echo "Use the --force flag to perform actual cleanup"
else
  echo "WARNING: Running in FORCE DELETE mode. Resources will be PERMANENTLY DELETED."
  read -p "Continue? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
  fi
fi
echo

# Function to clean up old ECR images
cleanup_ecr_images() {
  echo "Checking for old ECR images..."

  # Get all ECR repositories for the project
  REPOS=$(aws ecr describe-repositories --query "repositories[?contains(repositoryName, '$PROJECT')].repositoryName" --output text --region $AWS_REGION)

  if [ -z "$REPOS" ]; then
    echo "No ECR repositories found for project $PROJECT"
    return
  fi

  echo "Found $(echo $REPOS | wc -w) ECR repositories:"
  echo

  for repo in $REPOS; do
    echo "Scanning repository: $repo"

    # Get the latest image (to keep it)
    LATEST_IMAGE=$(aws ecr describe-images --repository-name "$repo" --query "sort_by(imageDetails,& imagePushedAt)[-1]" --output json --region $AWS_REGION)

    if [ -z "$LATEST_IMAGE" ] || [ "$LATEST_IMAGE" == "null" ]; then
      echo "No images found in repository $repo"
      continue
    fi

    # Extract details about the latest image
    LATEST_DIGEST=$(echo $LATEST_IMAGE | jq -r '.imageDigest')
    LATEST_TAG=$(echo $LATEST_IMAGE | jq -r '.imageTags[0] // "<untagged>"')
    LATEST_DATE=$(echo $LATEST_IMAGE | jq -r '.imagePushedAt')

    echo "Latest image: $LATEST_TAG pushed at $LATEST_DATE"

    # Find older images (all images except the latest one)
    OLD_IMAGES=$(aws ecr describe-images --repository-name "$repo" --query "imageDetails[?imageDigest!='$LATEST_DIGEST']" --output json --region $AWS_REGION)

    # Count the number of old images
    OLD_IMAGE_COUNT=$(echo $OLD_IMAGES | jq '. | length')

    if [ "$OLD_IMAGE_COUNT" == "0" ] || [ -z "$OLD_IMAGE_COUNT" ]; then
      echo "No older images found in repository $repo"
      continue
    fi

    echo "Found $OLD_IMAGE_COUNT older image(s) in $repo:"

    # List the old images
    echo $OLD_IMAGES | jq -c '.[]' | while read -r image; do
      DIGEST=$(echo $image | jq -r '.imageDigest')
      TAG=$(echo $image | jq -r '.imageTags[0] // "<untagged>"')
      DATE=$(echo $image | jq -r '.imagePushedAt')
      DIGEST_SHORT="${DIGEST:0:10}..."

      echo "  - Digest: ${DIGEST:0:7}... | Tag: $TAG | Date: $DATE"

      # Delete if not in dry run mode
      if [ "$DRY_RUN" = false ]; then
        aws ecr batch-delete-image --repository-name "$repo" --image-ids imageDigest="$DIGEST" --region $AWS_REGION >/dev/null
        echo "    DELETED"
      fi
    done

    # Skip if in dry run mode
    if [ "$DRY_RUN" = true ]; then
      echo "Skipping deletion of images from $repo"
    else
      echo "Deleted old images from $repo"
    fi
    echo
  done
}

# Function to clean up unattached EBS volumes
cleanup_ebs_volumes() {
  echo "Checking for unattached EBS volumes..."

  # Find unattached volumes with the project tag
  VOLUMES=$(aws ec2 describe-volumes --filters "Name=tag:Project,Values=$PROJECT" "Name=status,Values=available" --query "Volumes[*].{ID:VolumeId,Size:Size,Created:CreateTime}" --output json --region $AWS_REGION)

  if [ "$(echo $VOLUMES | jq '. | length')" == "0" ]; then
    echo "No unattached volumes found for project $PROJECT"
    echo
    return
  fi

  echo "Found $(echo $VOLUMES | jq '. | length') unattached volume(s):"

  # List and optionally delete each volume
  echo $VOLUMES | jq -c '.[]' | while read -r volume; do
    VOLUME_ID=$(echo $volume | jq -r '.ID')
    SIZE=$(echo $volume | jq -r '.Size')
    CREATED=$(echo $volume | jq -r '.Created')

    echo "  - $VOLUME_ID: ${SIZE}GB, created $CREATED"

    if [ "$DRY_RUN" = false ]; then
      aws ec2 delete-volume --volume-id $VOLUME_ID --region $AWS_REGION
      echo "    DELETED"
    fi
  done

  if [ "$DRY_RUN" = true ]; then
    echo "Skipping deletion of unattached volumes"
  fi
  echo
}

# Function to clean up old EBS snapshots
cleanup_old_snapshots() {
  echo "Checking for old EBS snapshots..."

  # Find snapshots with the project tag older than threshold
  SNAPSHOTS=$(aws ec2 describe-snapshots --owner-ids $AWS_ACCOUNT --filters "Name=tag:Project,Values=$PROJECT" --query "Snapshots[?StartTime<='$HUMAN_DATE'].{ID:SnapshotId,VolumeID:VolumeId,Created:StartTime,Size:VolumeSize}" --output json --region $AWS_REGION)

  if [ "$(echo $SNAPSHOTS | jq '. | length')" == "0" ]; then
    echo "No old snapshots found for project $PROJECT"
    echo
    return
  fi

  echo "Found $(echo $SNAPSHOTS | jq '. | length') old snapshot(s):"

  # List and optionally delete each snapshot
  echo $SNAPSHOTS | jq -c '.[]' | while read -r snapshot; do
    SNAPSHOT_ID=$(echo $snapshot | jq -r '.ID')
    VOLUME_ID=$(echo $snapshot | jq -r '.VolumeID')
    SIZE=$(echo $snapshot | jq -r '.Size')
    CREATED=$(echo $snapshot | jq -r '.Created')

    echo "  - $SNAPSHOT_ID: ${SIZE}GB, from volume $VOLUME_ID, created $CREATED"

    if [ "$DRY_RUN" = false ]; then
      aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID --region $AWS_REGION
      echo "    DELETED"
    fi
  done

  if [ "$DRY_RUN" = true ]; then
    echo "Skipping deletion of old snapshots"
  fi
  echo
}

# Function to clean up old CloudWatch log groups
cleanup_old_log_groups() {
  if [ "$VERBOSE" = true ]; then
    echo "Checking for old CloudWatch log groups..."

    # Find log groups with the project tag that haven't been written to since threshold
    LOG_GROUPS=$(aws logs describe-log-groups --query "logGroups[?contains(logGroupName, '$PROJECT')]" --output json --region $AWS_REGION)

    if [ "$(echo $LOG_GROUPS | jq '. | length')" == "0" ]; then
      echo "No log groups found for project $PROJECT"
      echo
      return
    fi

    OLD_LOG_GROUPS=0

    # Check each log group for recent activity
    echo $LOG_GROUPS | jq -c '.[]' | while read -r log_group; do
      LOG_GROUP_NAME=$(echo $log_group | jq -r '.logGroupName')
      LAST_WRITE=$(echo $log_group | jq -r '.creationTime // 0')
      # Convert milliseconds to seconds
      # LAST_WRITE_SEC=$(echo "$LAST_WRITE / 1000" | bc)
      LAST_WRITE_SEC=$((LAST_WRITE / 1000))

      # Check if the log group has any streams with recent events
      STREAMS=$(aws logs describe-log-streams --log-group-name "$LOG_GROUP_NAME" --order-by LastEventTime --descending --limit 1 --output json --region $AWS_REGION)

      if [ "$(echo $STREAMS | jq '.logStreams | length')" != "0" ]; then
        LATEST_STREAM_TIME=$(echo $STREAMS | jq -r '.logStreams[0].lastEventTimestamp // 0')
        # Convert milliseconds to seconds
        # LATEST_STREAM_TIME_SEC=$(echo "$LATEST_STREAM_TIME / 1000" | bc)
        LATEST_STREAM_TIME_SEC=$((LATEST_STREAM_TIME / 1000))

        # Use the most recent of creation time or latest event
        if [ $LATEST_STREAM_TIME_SEC -gt $LAST_WRITE_SEC ]; then
          LAST_WRITE_SEC=$LATEST_STREAM_TIME_SEC
        fi
      fi

      LAST_WRITE_DATE=$(date -d "@$LAST_WRITE_SEC" +"%Y-%m-%d %H:%M:%S")

      # Check if the log group is older than threshold
      if [ $LAST_WRITE_SEC -lt $THRESHOLD_DATE ]; then
        OLD_LOG_GROUPS=$((OLD_LOG_GROUPS + 1))
        echo "  - $LOG_GROUP_NAME: Last write on $LAST_WRITE_DATE"

        if [ "$DRY_RUN" = false ]; then
          aws logs delete-log-group --log-group-name "$LOG_GROUP_NAME" --region $AWS_REGION
          echo "    DELETED"
        fi
      fi
    done

    if [ $OLD_LOG_GROUPS -eq 0 ]; then
      echo "No old log groups found for project $PROJECT"
    else
      echo "Found $OLD_LOG_GROUPS old log group(s)"
      if [ "$DRY_RUN" = true ]; then
        echo "Skipping deletion of old log groups"
      fi
    fi
    echo
  fi
}

# Execute cleanup functions
cleanup_ecr_images
cleanup_ebs_volumes
cleanup_old_snapshots
if [ "$VERBOSE" = true ]; then
  cleanup_old_log_groups
fi

echo "Resource cleanup process completed."
if [ "$DRY_RUN" = true ]; then
  echo "This was a DRY RUN. No resources were actually deleted."
  echo "Use --force flag to perform actual deletions."
else
  echo "Resources have been deleted as specified."
fi
