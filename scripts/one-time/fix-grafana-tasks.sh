#!/bin/bash
# Script to fix Grafana service by stopping unhealthy tasks
# This script identifies and stops unhealthy Grafana tasks to allow ECS to replace them

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CLUSTER_NAME="prod-e-cluster"
SERVICE_NAME="grafana-service"
DRY_RUN=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --force)
      DRY_RUN=false
      shift
      ;;
    --cluster=*)
      CLUSTER_NAME="${1#*=}"
      shift
      ;;
    --service=*)
      SERVICE_NAME="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --force           Actually stop tasks (default is dry run)"
      echo "  --cluster=NAME    Specify the ECS cluster name (default: prod-e-cluster)"
      echo "  --service=NAME    Specify the ECS service name (default: grafana-service)"
      echo "  --help            Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}=== Grafana Task Cleanup Tool ===${NC}"
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
if $DRY_RUN; then
  echo -e "${YELLOW}Mode: Dry Run (no tasks will be stopped)${NC}"
  echo "Use --force to actually stop tasks"
else
  echo -e "${RED}Mode: Force (tasks will be stopped)${NC}"
fi

# Check AWS CLI configuration
echo -e "\n${BLUE}Checking AWS CLI configuration...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$ACCOUNT_ID" ]; then
  echo -e "${RED}Error: AWS CLI is not configured correctly${NC}"
  exit 1
fi
echo -e "${GREEN}AWS CLI configured for account: $ACCOUNT_ID${NC}"

# Get service details
echo -e "\n${BLUE}Checking service status...${NC}"
SERVICE_JSON=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME")
DESIRED_COUNT=$(echo "$SERVICE_JSON" | jq -r '.services[0].desiredCount')
RUNNING_COUNT=$(echo "$SERVICE_JSON" | jq -r '.services[0].runningCount')
TASK_DEFINITION=$(echo "$SERVICE_JSON" | jq -r '.services[0].taskDefinition')

echo "Desired task count: $DESIRED_COUNT"
echo "Running task count: $RUNNING_COUNT"
echo "Current task definition: $TASK_DEFINITION"

if [ "$RUNNING_COUNT" -le "$DESIRED_COUNT" ]; then
  echo -e "${GREEN}Service has the expected number of tasks running.${NC}"
else
  echo -e "${YELLOW}Service has more tasks running ($RUNNING_COUNT) than desired ($DESIRED_COUNT).${NC}"
fi

# Get all tasks for the service
echo -e "\n${BLUE}Checking task health status...${NC}"
TASK_ARNS=$(aws ecs list-tasks --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --query 'taskArns[]' --output text)

if [ -z "$TASK_ARNS" ]; then
  echo -e "${YELLOW}No tasks found for service $SERVICE_NAME${NC}"
  exit 0
fi

# Get task details
TASKS_JSON=$(aws ecs describe-tasks --cluster "$CLUSTER_NAME" --tasks $TASK_ARNS)

# Initialize arrays to store unhealthy and old task definition tasks
declare -a UNHEALTHY_TASKS
declare -a OLD_TASK_DEF_TASKS

# Process each task
while read -r line; do
  TASK_ARN=$(echo "$line" | cut -f1)
  HEALTH_STATUS=$(echo "$line" | cut -f2)
  TASK_DEF_ARN=$(echo "$line" | cut -f3)
  LAST_STATUS=$(echo "$line" | cut -f4)

  TASK_ID=$(echo "$TASK_ARN" | cut -d'/' -f3)

  # Check if task is using an old task definition
  if [ "$TASK_DEF_ARN" != "$TASK_DEFINITION" ]; then
    echo -e "${YELLOW}Task $TASK_ID is using old task definition: $TASK_DEF_ARN${NC}"
    OLD_TASK_DEF_TASKS+=("$TASK_ARN")
  fi

  # Check health status
  if [ "$HEALTH_STATUS" == "UNHEALTHY" ]; then
    echo -e "${RED}Task $TASK_ID is UNHEALTHY${NC}"
    UNHEALTHY_TASKS+=("$TASK_ARN")
  elif [ "$HEALTH_STATUS" == "UNKNOWN" ]; then
    echo -e "${YELLOW}Task $TASK_ID health status is UNKNOWN${NC}"
  else
    echo -e "${GREEN}Task $TASK_ID is $HEALTH_STATUS${NC}"
  fi
done < <(echo "$TASKS_JSON" | jq -r '.tasks[] | [.taskArn, .healthStatus, .taskDefinitionArn, .lastStatus] | @tsv')

# Stop unhealthy tasks
if [ ${#UNHEALTHY_TASKS[@]} -gt 0 ]; then
  echo -e "\n${BLUE}Found ${#UNHEALTHY_TASKS[@]} unhealthy tasks to stop${NC}"

  for TASK_ARN in "${UNHEALTHY_TASKS[@]}"; do
    TASK_ID=$(echo "$TASK_ARN" | cut -d'/' -f3)

    if $DRY_RUN; then
      echo -e "${YELLOW}[DRY RUN] Would stop unhealthy task: $TASK_ID${NC}"
    else
      echo -e "${RED}Stopping unhealthy task: $TASK_ID${NC}"
      aws ecs stop-task --cluster "$CLUSTER_NAME" --task "$TASK_ARN" --reason "Stopped by maintenance script due to unhealthy status"
      echo -e "${GREEN}Task stop command issued${NC}"
    fi
  done
else
  echo -e "\n${GREEN}No unhealthy tasks found${NC}"
fi

# Stop tasks using old task definitions
if [ ${#OLD_TASK_DEF_TASKS[@]} -gt 0 ]; then
  echo -e "\n${BLUE}Found ${#OLD_TASK_DEF_TASKS[@]} tasks using old task definitions${NC}"

  for TASK_ARN in "${OLD_TASK_DEF_TASKS[@]}"; do
    TASK_ID=$(echo "$TASK_ARN" | cut -d'/' -f3)

    if $DRY_RUN; then
      echo -e "${YELLOW}[DRY RUN] Would stop task using old task definition: $TASK_ID${NC}"
    else
      echo -e "${RED}Stopping task using old task definition: $TASK_ID${NC}"
      aws ecs stop-task --cluster "$CLUSTER_NAME" --task "$TASK_ARN" --reason "Stopped by maintenance script due to outdated task definition"
      echo -e "${GREEN}Task stop command issued${NC}"
    fi
  done
else
  echo -e "\n${GREEN}No tasks using old task definitions found${NC}"
fi

echo -e "\n${BLUE}Task cleanup process completed.${NC}"
if $DRY_RUN; then
  echo -e "${YELLOW}This was a DRY RUN. No tasks were actually stopped.${NC}"
  echo "Use --force flag to perform actual task stopping."
fi
