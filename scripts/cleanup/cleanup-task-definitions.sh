#!/bin/bash

# Script to clean up old ECS task definition revisions
# Keeps only the active revisions and the 3 most recent ones

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
  echo "Usage: $0 [OPTIONS]"
  echo "Clean up old ECS task definition revisions"
  echo ""
  echo "Options:"
  echo "  -r, --region REGION    AWS region (default: us-west-2)"
  echo "  -c, --cluster CLUSTER  ECS cluster name (default: prod-e-cluster)"
  echo "  -k, --keep NUMBER      Number of recent revisions to keep (default: 3)"
  echo "  -d, --dry-run          Show what would be deleted without actually deleting"
  echo "  -y, --yes              Skip confirmation prompt and proceed with deletion"
  echo "  -h, --help             Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --dry-run           Show what would be deleted without actually deleting"
  echo "  $0 --keep 5            Keep 5 most recent revisions for each family"
}

# Initialize variables
CLUSTER_NAME="prod-e-cluster"
KEEP_REVISIONS=3
DRY_RUN=false
SKIP_CONFIRMATION=false

# Process command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--region)
      AWS_REGION="$2"
      shift 2
      ;;
    -c|--cluster)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    -k|--keep)
      KEEP_REVISIONS="$2"
      shift 2
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -y|--yes)
      SKIP_CONFIRMATION=true
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

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}   ECS TASK DEFINITION CLEANUP UTILITY  ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo -e "Region: ${YELLOW}$AWS_REGION${NC}"
echo -e "Cluster: ${YELLOW}$CLUSTER_NAME${NC}"
echo -e "Keep revisions: ${YELLOW}$KEEP_REVISIONS${NC}"
echo -e "Dry run: ${YELLOW}$DRY_RUN${NC}"
echo ""

# Get all active task definition families
echo -e "${BLUE}Fetching active task definition families...${NC}"
FAMILIES=$(aws ecs list-task-definition-families --status ACTIVE --region $AWS_REGION --query "families" --output text)

if [[ -z "$FAMILIES" ]]; then
  echo -e "${RED}No task definition families found${NC}"
  exit 1
fi

# Get all services in the cluster to find active task definitions
echo -e "${BLUE}Fetching services in cluster ${YELLOW}$CLUSTER_NAME${NC}..."
SERVICES=$(aws ecs list-services --cluster $CLUSTER_NAME --region $AWS_REGION --query "serviceArns" --output text)

if [[ -z "$SERVICES" ]]; then
  echo -e "${YELLOW}No services found in cluster $CLUSTER_NAME${NC}"
fi

# Get active task definitions
ACTIVE_TASK_DEFS=()
for service in $SERVICES; do
  SERVICE_NAME=$(echo $service | awk -F/ '{print $NF}')
  TASK_DEF=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $AWS_REGION --query "services[0].taskDefinition" --output text)
  ACTIVE_TASK_DEFS+=("$TASK_DEF")
  echo -e "${GREEN}Service ${YELLOW}$SERVICE_NAME${GREEN} uses task definition ${YELLOW}$TASK_DEF${NC}"
done

# Process each family
for family in $FAMILIES; do
  echo -e "\n${BLUE}Processing family: ${YELLOW}$family${NC}"

  # Get all task definition revisions for this family
  TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $family --status ACTIVE --sort DESC --region $AWS_REGION --query "taskDefinitionArns" --output text)

  # Count total revisions
  TOTAL_REVISIONS=$(echo "$TASK_DEFS" | wc -w)
  echo -e "${GREEN}Found ${YELLOW}$TOTAL_REVISIONS${GREEN} active revisions${NC}"

  if [[ $TOTAL_REVISIONS -le $KEEP_REVISIONS ]]; then
    echo -e "${GREEN}Total revisions (${YELLOW}$TOTAL_REVISIONS${GREEN}) <= keep threshold (${YELLOW}$KEEP_REVISIONS${GREEN}), no cleanup needed${NC}"
    continue
  fi

  # List of task definitions to deregister
  REVISIONS_TO_DELETE=()

  # Convert task definitions to an array
  TASK_DEF_ARRAY=($TASK_DEFS)

  # Keep the most recent KEEP_REVISIONS
  for (( i=$KEEP_REVISIONS; i<$TOTAL_REVISIONS; i++ )); do
    # Skip if this is an active task definition
    SKIP=false
    for active_td in "${ACTIVE_TASK_DEFS[@]}"; do
      if [[ "${TASK_DEF_ARRAY[$i]}" == "$active_td" ]]; then
        echo -e "${YELLOW}Task definition ${TASK_DEF_ARRAY[$i]} is active in a service, skipping${NC}"
        SKIP=true
        break
      fi
    done

    if [[ "$SKIP" == "false" ]]; then
      REVISIONS_TO_DELETE+=("${TASK_DEF_ARRAY[$i]}")
    fi
  done

  # Display task definitions to delete
  if [[ ${#REVISIONS_TO_DELETE[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No task definitions to delete for family $family${NC}"
  else
    echo -e "${BLUE}Task definitions to deregister for family $family:${NC}"
    for td in "${REVISIONS_TO_DELETE[@]}"; do
      TD_SHORT=$(echo $td | awk -F/ '{print $NF}')
      echo -e "  ${RED}- $TD_SHORT${NC}"
    done

    # Confirm before deleting
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${YELLOW}Dry run mode, no task definitions will be deregistered${NC}"
    else
      if [[ "$SKIP_CONFIRMATION" == "false" ]]; then
        read -p "Do you want to deregister these task definitions? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
          echo -e "${YELLOW}Skipping deregistration for family $family${NC}"
          continue
        fi
      fi

      # Deregister task definitions
      echo -e "${BLUE}Deregistering task definitions...${NC}"
      for td in "${REVISIONS_TO_DELETE[@]}"; do
        TD_SHORT=$(echo $td | awk -F/ '{print $NF}')
        echo -e "${YELLOW}Deregistering $TD_SHORT...${NC}"

        if ! aws ecs deregister-task-definition --task-definition $TD_SHORT --region $AWS_REGION > /dev/null; then
          echo -e "${RED}Failed to deregister $TD_SHORT${NC}"
        else
          echo -e "${GREEN}Successfully deregistered $TD_SHORT${NC}"
        fi
      done
    fi
  fi
done

echo -e "\n${BLUE}=======================================${NC}"
echo -e "${BLUE}         CLEANUP COMPLETE              ${NC}"
echo -e "${BLUE}=======================================${NC}"
