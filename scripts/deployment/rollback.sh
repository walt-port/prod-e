#!/bin/bash

# Rollback Script for Production Experience Showcase
# This script handles the rollback of deployments

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

# Print usage information
usage() {
  echo "Usage: $0 [OPTIONS] [SERVICE_NAME]"
  echo "Roll back a deployment for the Production Experience Showcase"
  echo ""
  echo "Options:"
  echo "  -c, --cluster NAME       ECS cluster name (default: prod-e-cluster)"
  echo "  -t, --tag TAG            Previous container image tag to rollback to"
  echo "  -r, --repository NAME    ECR repository name"
  echo "  -n, --tf-state-bucket    Terraform state bucket name (default: prod-e-terraform-state)"
  echo "  -a, --auto-approve       Skip confirmation prompts"
  echo "  -f, --force              Force rollback even if health checks pass"
  echo "  -h, --help               Display this help message"
  echo ""
  echo "SERVICE_NAME can be one of: backend, grafana, prometheus, or 'all' to check everything"
  echo ""
  echo "Examples:"
  echo "  $0 backend                           Roll back backend service using previous task definition"
  echo "  $0 -t v1.0.0 -r prod-e-backend backend  Roll back to specific image tag v1.0.0"
  echo "  $0 --auto-approve all                Roll back all services without confirmation"
}

# Process command line arguments
CLUSTER_NAME="prod-e-cluster"
IMAGE_TAG=""
ECR_REPO=""
TF_STATE_BUCKET="prod-e-terraform-state"
AUTO_APPROVE=false
FORCE_ROLLBACK=false
SERVICE_NAME=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--cluster)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    -t|--tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    -r|--repository)
      ECR_REPO="$2"
      shift 2
      ;;
    -n|--tf-state-bucket)
      TF_STATE_BUCKET="$2"
      shift 2
      ;;
    -a|--auto-approve)
      AUTO_APPROVE=true
      shift
      ;;
    -f|--force)
      FORCE_ROLLBACK=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ -z "$SERVICE_NAME" ]; then
        SERVICE_NAME="$1"
        shift
      else
        echo "Unknown option: $1"
        usage
        exit 1
      fi
      ;;
  esac
done

# Validate SERVICE_NAME
if [ -z "$SERVICE_NAME" ]; then
  echo -e "${RED}Error: SERVICE_NAME is required${NC}"
  usage
  exit 1
fi

# Map service name to ECS service and ECR repository
map_service_to_ecs() {
  local svc=$1
  case $svc in
    backend)
      echo "prod-e-backend-service"
      ;;
    grafana)
      echo "prod-e-grafana-service"
      ;;
    prometheus)
      echo "prod-e-prom-service"
      ;;
    *)
      echo ""
      ;;
  esac
}

map_service_to_repo() {
  local svc=$1
  case $svc in
    backend)
      echo "prod-e-backend"
      ;;
    grafana)
      echo "prod-e-grafana"
      ;;
    prometheus)
      echo "prod-e-prometheus"
      ;;
    *)
      echo ""
      ;;
  esac
}

# Check cluster exists
echo -e "${BLUE}Checking if ECS cluster $CLUSTER_NAME exists...${NC}"
CLUSTER_ARN=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$AWS_REGION" --query "clusters[0].clusterArn" --output text)
if [ "$CLUSTER_ARN" == "None" ]; then
  echo -e "${RED}Error: ECS cluster $CLUSTER_NAME not found${NC}"
  exit 1
fi
echo -e "${GREEN}ECS cluster $CLUSTER_NAME found${NC}"

# Check service health
check_service_health() {
  local service_name=$1
  local ecs_service=$(map_service_to_ecs "$service_name")

  if [ -z "$ecs_service" ]; then
    echo -e "${RED}Unknown service: $service_name${NC}"
    return 1
  fi

  echo -e "${BLUE}Checking health of $service_name ($ecs_service)...${NC}"

  # Get service details
  SERVICE_DATA=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$ecs_service" --region "$AWS_REGION" --query "services[0]")

  # Check if service exists
  SERVICE_STATUS=$(echo "$SERVICE_DATA" | jq -r '.status')
  if [ "$SERVICE_STATUS" != "ACTIVE" ]; then
    echo -e "${RED}Service $ecs_service is not active (Status: $SERVICE_STATUS)${NC}"
    return 1
  fi

  # Check desired vs running count
  DESIRED_COUNT=$(echo "$SERVICE_DATA" | jq -r '.desiredCount')
  RUNNING_COUNT=$(echo "$SERVICE_DATA" | jq -r '.runningCount')

  if [ "$RUNNING_COUNT" -lt "$DESIRED_COUNT" ]; then
    echo -e "${RED}Service $ecs_service is degraded ($RUNNING_COUNT/$DESIRED_COUNT tasks running)${NC}"
    return 1
  fi

  # Check deployment status
  DEPLOYMENTS=$(echo "$SERVICE_DATA" | jq -r '.deployments')
  PRIMARY_DEPLOYMENT=$(echo "$DEPLOYMENTS" | jq -r '.[] | select(.status=="PRIMARY")')
  ROLLOUT_STATE=$(echo "$PRIMARY_DEPLOYMENT" | jq -r '.rolloutState')

  if [ "$ROLLOUT_STATE" != "COMPLETED" ]; then
    echo -e "${YELLOW}Service $ecs_service deployment is not complete (State: $ROLLOUT_STATE)${NC}"
    return 1
  fi

  echo -e "${GREEN}Service $ecs_service is healthy${NC}"
  return 0
}

# Perform the rollback
rollback_service() {
  local service_name=$1
  local ecs_service=$(map_service_to_ecs "$service_name")

  if [ -z "$ecs_service" ]; then
    echo -e "${RED}Unknown service: $service_name${NC}"
    return 1
  fi

  echo -e "${BLUE}Preparing to roll back $service_name ($ecs_service)...${NC}"

  # Check health if not forcing rollback
  if [ "$FORCE_ROLLBACK" != true ]; then
    if check_service_health "$service_name"; then
      echo -e "${YELLOW}Service $service_name appears to be healthy.${NC}"

      if [ "$AUTO_APPROVE" != true ]; then
        read -p "Continue with rollback anyway? (y/n): " CONFIRM
        if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
          echo -e "${BLUE}Rollback cancelled for $service_name${NC}"
          return 0
        fi
      fi
    fi
  fi

  # If image tag is provided, use it for rollback
  if [ -n "$IMAGE_TAG" ]; then
    local repo=${ECR_REPO:-$(map_service_to_repo "$service_name")}

    if [ -z "$repo" ]; then
      echo -e "${RED}Could not determine ECR repository for $service_name${NC}"
      return 1
    fi

    echo -e "${BLUE}Rolling back to image tag $IMAGE_TAG in repository $repo...${NC}"

    # Get AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

    # Construct the full repository URI
    REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}:${IMAGE_TAG}"

    # Verify the image exists
    IMAGE_CHECK=$(aws ecr describe-images --repository-name "$repo" --image-ids imageTag="$IMAGE_TAG" --region "$AWS_REGION" 2>&1) || {
      echo -e "${RED}Error: Image tag $IMAGE_TAG not found in repository $repo${NC}"
      return 1
    }

    # Update the service to use the specified image
    echo -e "${BLUE}Updating service to use image $REPO_URI...${NC}"
    aws ecs update-service --cluster "$CLUSTER_NAME" --service "$ecs_service" \
      --force-new-deployment \
      --region "$AWS_REGION" > /dev/null

    echo -e "${GREEN}Rollback triggered for $service_name to image tag $IMAGE_TAG${NC}"

  else

    # Get previous task definition
    echo -e "${BLUE}Finding previous task definition for $ecs_service...${NC}"

    # Get current task definition
    CURRENT_TASK_DEF_ARN=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$ecs_service" \
      --query "services[0].taskDefinition" --output text --region "$AWS_REGION")

    CURRENT_TASK_DEF_FAMILY=$(echo "$CURRENT_TASK_DEF_ARN" | cut -d'/' -f2 | cut -d':' -f1)
    CURRENT_TASK_DEF_REVISION=$(echo "$CURRENT_TASK_DEF_ARN" | cut -d'/' -f2 | cut -d':' -f2)

    # We need at least revision 2 to roll back
    if [ "$CURRENT_TASK_DEF_REVISION" -lt 2 ]; then
      echo -e "${RED}No previous task definition found for $ecs_service (current revision: $CURRENT_TASK_DEF_REVISION)${NC}"
      return 1
    fi

    # Calculate previous revision
    PREV_REVISION=$((CURRENT_TASK_DEF_REVISION - 1))
    PREV_TASK_DEF="${CURRENT_TASK_DEF_FAMILY}:${PREV_REVISION}"

    echo -e "${BLUE}Rolling back from $CURRENT_TASK_DEF_FAMILY:$CURRENT_TASK_DEF_REVISION to $PREV_TASK_DEF${NC}"

    # Update the service to use the previous task definition
    aws ecs update-service --cluster "$CLUSTER_NAME" --service "$ecs_service" \
      --task-definition "$PREV_TASK_DEF" \
      --force-new-deployment \
      --region "$AWS_REGION" > /dev/null

    echo -e "${GREEN}Rollback triggered for $service_name to task definition $PREV_TASK_DEF${NC}"
  fi

  # Wait for deployment to start
  echo -e "${YELLOW}Waiting for rollback deployment to start...${NC}"
  sleep 5

  # Monitor deployment
  echo -e "${BLUE}Monitoring rollback deployment status:${NC}"
  local start_time=$(date +%s)
  local timeout=600  # 10 minutes

  while true; do
    # Get deployment status
    DEPLOYMENT_STATUS=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$ecs_service" \
      --region "$AWS_REGION" --query "services[0].deployments[?status=='PRIMARY'].{rolloutState:rolloutState,desiredCount:desiredCount,runningCount:runningCount,pendingCount:pendingCount,failedCount:failedCount}" \
      --output json | jq -r '.[0]')

    ROLLOUT_STATE=$(echo "$DEPLOYMENT_STATUS" | jq -r '.rolloutState')
    DESIRED=$(echo "$DEPLOYMENT_STATUS" | jq -r '.desiredCount')
    RUNNING=$(echo "$DEPLOYMENT_STATUS" | jq -r '.runningCount')
    PENDING=$(echo "$DEPLOYMENT_STATUS" | jq -r '.pendingCount')
    FAILED=$(echo "$DEPLOYMENT_STATUS" | jq -r '.failedCount')

    # Calculate elapsed time
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))

    echo -e "Status: $ROLLOUT_STATE | Running: $RUNNING/$DESIRED | Pending: $PENDING | Failed: $FAILED | Elapsed: ${elapsed}s"

    # Check if deployment completed or failed
    if [ "$ROLLOUT_STATE" == "COMPLETED" ]; then
      echo -e "${GREEN}Rollback deployment completed successfully for $service_name${NC}"
      break
    elif [ "$ROLLOUT_STATE" == "FAILED" ]; then
      echo -e "${RED}Rollback deployment failed for $service_name${NC}"
      break
    elif [ $elapsed -ge $timeout ]; then
      echo -e "${RED}Timed out waiting for rollback deployment to complete for $service_name${NC}"
      break
    fi

    # Wait before checking again
    sleep 10
  done

  return 0
}

# Rollback Terraform state (if applicable)
rollback_terraform() {
  echo -e "${BLUE}Checking for previous Terraform state versions...${NC}"

  # Check if state bucket exists
  if ! aws s3api head-bucket --bucket "$TF_STATE_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
    echo -e "${RED}Terraform state bucket $TF_STATE_BUCKET not found${NC}"
    return 1
  fi

  # List versions of the state file
  VERSIONS=$(aws s3api list-object-versions --bucket "$TF_STATE_BUCKET" --prefix "terraform.tfstate" \
    --query "sort_by(Versions, &LastModified)[-2:]" --output json)

  # We need at least 2 versions to roll back
  VERSION_COUNT=$(echo "$VERSIONS" | jq length)
  if [ "$VERSION_COUNT" -lt 2 ]; then
    echo -e "${YELLOW}Not enough Terraform state versions to perform rollback (found $VERSION_COUNT)${NC}"
    return 1
  fi

  # Get the previous version ID
  CURRENT_VERSION=$(echo "$VERSIONS" | jq -r '.[-1].VersionId')
  PREVIOUS_VERSION=$(echo "$VERSIONS" | jq -r '.[-2].VersionId')
  PREVIOUS_DATE=$(echo "$VERSIONS" | jq -r '.[-2].LastModified')

  echo -e "${BLUE}Found previous Terraform state from $PREVIOUS_DATE (VersionId: $PREVIOUS_VERSION)${NC}"

  if [ "$AUTO_APPROVE" != true ]; then
    read -p "Roll back Terraform state to this version? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
      echo -e "${BLUE}Terraform state rollback cancelled${NC}"
      return 0
    fi
  fi

  # Backup current state first
  echo -e "${BLUE}Backing up current Terraform state...${NC}"
  BACKUP_TIME=$(date +%Y%m%d-%H%M%S)
  aws s3 cp "s3://${TF_STATE_BUCKET}/terraform.tfstate" "s3://${TF_STATE_BUCKET}/backups/terraform.tfstate.backup-${BACKUP_TIME}"

  # Copy the previous version to current
  echo -e "${BLUE}Rolling back to previous Terraform state...${NC}"
  aws s3api copy-object --bucket "$TF_STATE_BUCKET" --copy-source "$TF_STATE_BUCKET/terraform.tfstate?versionId=$PREVIOUS_VERSION" \
    --key "terraform.tfstate" --region "$AWS_REGION"

  echo -e "${GREEN}Terraform state successfully rolled back to version from $PREVIOUS_DATE${NC}"
  echo -e "${GREEN}Previous state backed up to s3://${TF_STATE_BUCKET}/backups/terraform.tfstate.backup-${BACKUP_TIME}${NC}"

  return 0
}

# Main execution
if [ "$SERVICE_NAME" == "all" ]; then
  echo -e "${BLUE}Preparing to check and potentially roll back all services...${NC}"

  # Check health of all services
  for svc in backend grafana prometheus; do
    check_service_health "$svc"
  done

  # Ask for confirmation
  if [ "$AUTO_APPROVE" != true ]; then
    read -p "Roll back all services? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
      echo -e "${BLUE}Rollback cancelled${NC}"
      exit 0
    fi
  fi

  # Perform rollback for all services
  for svc in backend grafana prometheus; do
    rollback_service "$svc"
  done

  # Check if we should also roll back Terraform state
  if [ "$AUTO_APPROVE" != true ]; then
    read -p "Also roll back Terraform state? (y/n): " CONFIRM
    if [ "$CONFIRM" == "y" ] || [ "$CONFIRM" == "Y" ]; then
      rollback_terraform
    fi
  fi
else
  # Roll back a single service
  rollback_service "$SERVICE_NAME"

  # Only suggest Terraform rollback for infrastructure-related services
  if [ "$SERVICE_NAME" == "backend" ]; then
    if [ "$AUTO_APPROVE" != true ]; then
      read -p "Also roll back Terraform state? (y/n): " CONFIRM
      if [ "$CONFIRM" == "y" ] || [ "$CONFIRM" == "Y" ]; then
        rollback_terraform
      fi
    fi
  fi
fi

echo -e "${GREEN}Rollback operations completed${NC}"
exit 0
