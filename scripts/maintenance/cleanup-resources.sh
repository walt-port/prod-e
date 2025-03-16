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
KEEP_LATEST=5  # Number of latest resource versions to keep

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
    --keep=*) KEEP_LATEST="${1#*=}" ;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --force         Perform actual deletion (default: dry run)"
      echo "  --days=N        Set age threshold to N days (default: 7)"
      echo "  --region=REGION Set AWS region (default: us-west-2)"
      echo "  --verbose       Display more detailed information"
      echo "  --keep=N        Number of latest versions to keep (default: 5)"
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
echo "Keep latest: $KEEP_LATEST versions"
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

    # Get all images in the repository
    ALL_IMAGES=$(aws ecr describe-images --repository-name "$repo" --query "sort_by(imageDetails,& imagePushedAt)" --output json --region $AWS_REGION)

    # Count total images
    TOTAL_IMAGES=$(echo $ALL_IMAGES | jq '. | length')

    if [ -z "$TOTAL_IMAGES" ] || [ "$TOTAL_IMAGES" == "0" ] || [ "$TOTAL_IMAGES" == "null" ]; then
      echo "No images found in repository $repo"
      continue
    fi

    echo "Found $TOTAL_IMAGES total images in $repo"

    # If we have fewer images than what we want to keep, do nothing
    if [ "$TOTAL_IMAGES" -le "$KEEP_LATEST" ]; then
      echo "Keeping all $TOTAL_IMAGES images as it's <= $KEEP_LATEST (keep-latest setting)"
      continue
    fi

    # Calculate number of images to delete
    DELETE_COUNT=$((TOTAL_IMAGES - KEEP_LATEST))

    echo "Will keep $KEEP_LATEST latest images and delete $DELETE_COUNT older ones"

    # Get images to delete (all except the latest N)
    IMAGES_TO_DELETE=$(echo $ALL_IMAGES | jq '.[0:'$DELETE_COUNT']')

    # List the images to delete
    echo $IMAGES_TO_DELETE | jq -c '.[]' | while read -r image; do
      DIGEST=$(echo $image | jq -r '.imageDigest')
      TAGS=$(echo $image | jq -r '.imageTags // ["<untagged>"] | join(", ")')
      DATE=$(echo $image | jq -r '.imagePushedAt')
      DIGEST_SHORT="${DIGEST:0:10}..."

      echo "  - Digest: ${DIGEST:0:7}... | Tags: $TAGS | Date: $DATE"

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
  VOLUMES=$(aws ec2 describe-volumes --filters "Name=status,Values=available" --query "Volumes[*].{ID:VolumeId,Size:Size,Created:CreateTime}" --output json --region $AWS_REGION)

  if [ "$(echo $VOLUMES | jq '. | length')" == "0" ]; then
    echo "No unattached volumes found"
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
  SNAPSHOTS=$(aws ec2 describe-snapshots --owner-ids $AWS_ACCOUNT --query "Snapshots[?StartTime<='$HUMAN_DATE'].{ID:SnapshotId,VolumeID:VolumeId,Created:StartTime,Size:VolumeSize}" --output json --region $AWS_REGION)

  if [ "$(echo $SNAPSHOTS | jq '. | length')" == "0" ]; then
    echo "No old snapshots found"
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
  echo "Checking for old CloudWatch log groups..."

  # Find log groups that haven't been written to since threshold
  LOG_GROUPS=$(aws logs describe-log-groups --output json --region $AWS_REGION)

  if [ "$(echo $LOG_GROUPS | jq '.logGroups | length')" == "0" ]; then
    echo "No log groups found"
    echo
    return
  fi

  OLD_LOG_GROUPS=0

  # Check each log group for recent activity
  echo $LOG_GROUPS | jq -c '.logGroups[]' | while read -r log_group; do
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
    echo "No old log groups found"
  else
    echo "Found $OLD_LOG_GROUPS old log group(s)"
    if [ "$DRY_RUN" = true ]; then
      echo "Skipping deletion of old log groups"
    fi
  fi
  echo
}

# Function to clean up old ECS task definitions
cleanup_old_task_definitions() {
  echo "Checking for old ECS task definitions..."

  # Get task definition families for the project
  FAMILIES=$(aws ecs list-task-definition-families --status ACTIVE --family-prefix "$PROJECT" --query "families" --output text --region $AWS_REGION)
  # Add other task families we care about
  FAMILIES="$FAMILIES grafana prom"

  if [ -z "$FAMILIES" ]; then
    echo "No task definition families found for project $PROJECT"
    echo
    return
  fi

  for family in $FAMILIES; do
    echo "Checking task definitions for family: $family"

    # Get all revisions for this family, sorted by revision number
    TASK_DEFS=$(aws ecs list-task-definitions --family-prefix "$family" --sort DESC --status ACTIVE --query "taskDefinitionArns" --output json --region $AWS_REGION)

    TOTAL_TASK_DEFS=$(echo $TASK_DEFS | jq '. | length')

    if [ "$TOTAL_TASK_DEFS" == "0" ] || [ -z "$TOTAL_TASK_DEFS" ]; then
      echo "No task definitions found for family $family"
      continue
    fi

    echo "Found $TOTAL_TASK_DEFS task definition(s) for family $family"

    # If we have fewer task defs than what we want to keep, do nothing
    if [ "$TOTAL_TASK_DEFS" -le "$KEEP_LATEST" ]; then
      echo "Keeping all $TOTAL_TASK_DEFS task definitions as it's <= $KEEP_LATEST (keep-latest setting)"
      continue
    fi

    # Calculate how many to delete
    DELETE_COUNT=$((TOTAL_TASK_DEFS - KEEP_LATEST))

    echo "Will keep $KEEP_LATEST latest revisions and delete $DELETE_COUNT older ones"

    # Get task definitions to delete (all except the latest N)
    TASK_DEFS_TO_DELETE=$(echo $TASK_DEFS | jq '.['"$KEEP_LATEST"':]')

    # Process each task definition
    echo $TASK_DEFS_TO_DELETE | jq -r '.[]' | while read -r task_def_arn; do
      # Extract the revision number from the ARN
      REVISION=$(echo $task_def_arn | awk -F':' '{print $NF}')

      echo "  - Deregistering task definition: $family:$REVISION"

      if [ "$DRY_RUN" = false ]; then
        aws ecs deregister-task-definition --task-definition "$family:$REVISION" --region $AWS_REGION > /dev/null
        echo "    DEREGISTERED"
      fi
    done

    if [ "$DRY_RUN" = true ]; then
      echo "Skipping deregistration of task definitions for family $family"
    fi
    echo
  done
}

# Function to clean up idle Lambda function versions
cleanup_lambda_versions() {
  echo "Checking for old Lambda function versions..."

  # Get Lambda functions for the project
  FUNCTIONS=$(aws lambda list-functions --region $AWS_REGION --query "Functions[?contains(FunctionName, '$PROJECT')].FunctionName" --output text)

  if [ -z "$FUNCTIONS" ]; then
    echo "No Lambda functions found for project $PROJECT"
    echo
    return
  fi

  for function in $FUNCTIONS; do
    echo "Checking versions for Lambda function: $function"

    # Get all versions except $LATEST
    VERSIONS=$(aws lambda list-versions-by-function --function-name "$function" --region $AWS_REGION --query "Versions[?Version!='$LATEST']" --output json)

    TOTAL_VERSIONS=$(echo $VERSIONS | jq '. | length')

    if [ "$TOTAL_VERSIONS" == "0" ] || [ -z "$TOTAL_VERSIONS" ]; then
      echo "No versions found for function $function"
      continue
    fi

    echo "Found $TOTAL_VERSIONS version(s) for function $function"

    # If we have fewer versions than what we want to keep, do nothing
    if [ "$TOTAL_VERSIONS" -le "$KEEP_LATEST" ]; then
      echo "Keeping all $TOTAL_VERSIONS versions as it's <= $KEEP_LATEST (keep-latest setting)"
      continue
    fi

    # Sort versions by LastModified date
    SORTED_VERSIONS=$(echo $VERSIONS | jq 'sort_by(.LastModified)')

    # Calculate how many to delete
    DELETE_COUNT=$((TOTAL_VERSIONS - KEEP_LATEST))

    echo "Will keep $KEEP_LATEST latest versions and delete $DELETE_COUNT older ones"

    # Get versions to delete (all except the latest N)
    VERSIONS_TO_DELETE=$(echo $SORTED_VERSIONS | jq '.[0:'$DELETE_COUNT']')

    # Process each version
    echo $VERSIONS_TO_DELETE | jq -c '.[]' | while read -r version; do
      VERSION_NUM=$(echo $version | jq -r '.Version')
      LAST_MODIFIED=$(echo $version | jq -r '.LastModified')

      echo "  - Deleting version $VERSION_NUM (modified: $LAST_MODIFIED)"

      if [ "$DRY_RUN" = false ]; then
        aws lambda delete-function --function-name "$function" --qualifier "$VERSION_NUM" --region $AWS_REGION
        echo "    DELETED"
      fi
    done

    if [ "$DRY_RUN" = true ]; then
      echo "Skipping deletion of Lambda versions for function $function"
    fi
    echo
  done
}

# Function to find and clean up unused security groups
cleanup_unused_security_groups() {
  echo "Checking for unused security groups..."

  # Get all security groups
  SECURITY_GROUPS=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName!='default']" --output json --region $AWS_REGION)

  if [ "$(echo $SECURITY_GROUPS | jq '. | length')" == "0" ]; then
    echo "No non-default security groups found"
    echo
    return
  fi

  echo "Scanning for unused security groups:"

  # Check each security group
  echo $SECURITY_GROUPS | jq -c '.[]' | while read -r sg; do
    SG_ID=$(echo $sg | jq -r '.GroupId')
    SG_NAME=$(echo $sg | jq -r '.GroupName')
    SG_DESC=$(echo $sg | jq -r '.Description')

    # Skip default security groups
    if [[ "$SG_NAME" == "default" ]]; then
      continue
    fi

    # Check if the security group is in use
    IN_USE=false

    # Check EC2 instances
    EC2_USAGE=$(aws ec2 describe-instances --filters "Name=instance.group-id,Values=$SG_ID" --query "Reservations[*].Instances[*].InstanceId" --output text --region $AWS_REGION)

    # Check ENIs
    ENI_USAGE=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$SG_ID" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text --region $AWS_REGION)

    # Check Load Balancers
    LB_USAGE=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?SecurityGroups[?contains(@, '$SG_ID')]].LoadBalancerArn" --output text --region $AWS_REGION)

    # Check RDS instances
    RDS_USAGE=$(aws rds describe-db-instances --query "DBInstances[?VpcSecurityGroups[?VpcSecurityGroupId=='$SG_ID']].DBInstanceIdentifier" --output text --region $AWS_REGION)

    # Check Lambda functions
    LAMBDA_USAGE=$(aws lambda list-functions --query "Functions[?VpcConfig.SecurityGroupIds[?contains(@, '$SG_ID')]].FunctionName" --output text --region $AWS_REGION)

    # If any of these are non-empty, the security group is in use
    if [[ -n "$EC2_USAGE" || -n "$ENI_USAGE" || -n "$LB_USAGE" || -n "$RDS_USAGE" || -n "$LAMBDA_USAGE" ]]; then
      IN_USE=true
    fi

    if [ "$IN_USE" = false ]; then
      echo "  - Unused security group: $SG_NAME ($SG_ID) - $SG_DESC"

      if [ "$DRY_RUN" = false ]; then
        # Check if this security group is referenced by other security groups
        REFERENCED_BY=$(aws ec2 describe-security-groups --query "SecurityGroups[?IpPermissions[?UserIdGroupPairs[?GroupId=='$SG_ID']]].GroupId" --output text --region $AWS_REGION)

        if [ -n "$REFERENCED_BY" ]; then
          echo "    Cannot delete: Referenced by security group(s): $REFERENCED_BY"
        else
          # Try to delete the security group
          if aws ec2 delete-security-group --group-id "$SG_ID" --region $AWS_REGION 2>/dev/null; then
            echo "    DELETED"
          else
            echo "    Failed to delete: Security group may be in use or have dependencies"
          fi
        fi
      fi
    else
      if [ "$VERBOSE" = true ]; then
        echo "  - Security group in use: $SG_NAME ($SG_ID)"
      fi
    fi
  done

  if [ "$DRY_RUN" = true ]; then
    echo "Skipping deletion of unused security groups"
  fi
  echo
}

# Execute cleanup functions
cleanup_ecr_images
cleanup_ebs_volumes
cleanup_old_snapshots
cleanup_old_log_groups
cleanup_old_task_definitions
cleanup_lambda_versions
cleanup_unused_security_groups

echo "Resource cleanup process completed."
if [ "$DRY_RUN" = true ]; then
  echo "This was a DRY RUN. No resources were actually deleted."
  echo "Use --force flag to perform actual deletions."
else
  echo "Resources have been deleted as specified."
fi
