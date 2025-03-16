#!/bin/bash

# Script to fix Prometheus service health issues
# This script updates the Prometheus task definition with a proper health check
# and registers it with the load balancer target group

# Set default values
AWS_REGION="us-west-2"
CLUSTER="prod-e-cluster"
SERVICE="prod-e-prom-service"
DRY_RUN=true

# Color coding for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --force)
      DRY_RUN=false
      shift
      ;;
    --region=*)
      AWS_REGION="${1#*=}"
      shift
      ;;
    --cluster=*)
      CLUSTER="${1#*=}"
      shift
      ;;
    --service=*)
      SERVICE="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --force           Actually apply changes (default is dry run)"
      echo "  --region=REGION   Specify the AWS region (default: us-west-2)"
      echo "  --cluster=CLUSTER Specify the ECS cluster (default: prod-e-cluster)"
      echo "  --service=SERVICE Specify the ECS service (default: prod-e-prom-service)"
      echo "  --help            Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Display the current mode
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}Running in DRY RUN mode. No changes will be made.${NC}"
  echo -e "${YELLOW}Use --force to apply changes.${NC}"
else
  echo -e "${RED}Running in FORCE mode. Changes will be applied.${NC}"
fi

echo -e "${BLUE}AWS Region: ${NC}$AWS_REGION"
echo -e "${BLUE}Cluster: ${NC}$CLUSTER"
echo -e "${BLUE}Service: ${NC}$SERVICE"
echo ""

# Check AWS CLI configuration
echo -e "${BLUE}Checking AWS CLI configuration...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$ACCOUNT_ID" ]; then
  echo -e "${RED}Error: Unable to retrieve AWS account ID. Check AWS CLI configuration.${NC}"
  exit 1
else
  echo -e "${GREEN}AWS CLI is configured for account: $ACCOUNT_ID${NC}"
fi

# Get current task definition
echo -e "${BLUE}Retrieving current task definition...${NC}"
TASK_DEF_ARN=$(aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $AWS_REGION --query "services[0].taskDefinition" --output text)
if [ -z "$TASK_DEF_ARN" ]; then
  echo -e "${RED}Error: Could not retrieve task definition from service $SERVICE.${NC}"
  exit 1
fi
echo -e "${GREEN}Current task definition: $TASK_DEF_ARN${NC}"

# Get task definition family and revision from ARN
echo "Extracting task definition information..."
FULL_TASK_DEF=$(echo $TASK_DEF_ARN | sed 's/.*task-definition\///')
echo -e "${BLUE}Task Definition: ${FULL_TASK_DEF}${NC}"

# Extract family from the full task definition name
TASK_DEF_FAMILY=$(echo $FULL_TASK_DEF | cut -d':' -f1)
echo -e "${BLUE}Task Definition Family: ${TASK_DEF_FAMILY}${NC}"

# Get task definition details
echo -e "${BLUE}Retrieving task definition details...${NC}"
TASK_DEF=$(aws ecs describe-task-definition --task-definition $FULL_TASK_DEF --region $AWS_REGION)
if [ -z "$TASK_DEF" ]; then
  echo -e "${RED}Error: Could not retrieve task definition details.${NC}"
  exit 1
fi

# Extract task definition components
CONTAINER_DEFS=$(echo $TASK_DEF | jq '.taskDefinition.containerDefinitions')
TASK_ROLE=$(echo $TASK_DEF | jq -r '.taskDefinition.taskRoleArn')
EXECUTION_ROLE=$(echo $TASK_DEF | jq -r '.taskDefinition.executionRoleArn')
NETWORK_MODE=$(echo $TASK_DEF | jq -r '.taskDefinition.networkMode')
CPU=$(echo $TASK_DEF | jq -r '.taskDefinition.cpu')
MEMORY=$(echo $TASK_DEF | jq -r '.taskDefinition.memory')
REQUIRES_COMPATIBILITIES=$(echo $TASK_DEF | jq '.taskDefinition.requiresCompatibilities')
VOLUMES=$(echo $TASK_DEF | jq '.taskDefinition.volumes')

echo -e "${BLUE}Modifying container definitions to add health check...${NC}"
CONTAINER_DEFS_WITH_HEALTH=$(echo $CONTAINER_DEFS | jq '.[0] += {"healthCheck": {"command": ["CMD-SHELL", "nc -z localhost 9090 || exit 1"], "interval": 30, "timeout": 5, "retries": 3, "startPeriod": 60}}')
CONTAINER_DEFS_WITH_COMMAND=$(echo $CONTAINER_DEFS_WITH_HEALTH | jq '.[0] += {"command": ["--web.external-url=/prometheus", "--web.route-prefix=/"]}')

# Create the updated task definition json
UPDATED_TASK_DEF=$(cat <<EOF
{
  "family": "$TASK_DEF_FAMILY",
  "taskRoleArn": "$TASK_ROLE",
  "executionRoleArn": "$EXECUTION_ROLE",
  "networkMode": "$NETWORK_MODE",
  "containerDefinitions": $CONTAINER_DEFS_WITH_COMMAND,
  "volumes": $VOLUMES,
  "requiresCompatibilities": $REQUIRES_COMPATIBILITIES,
  "cpu": "$CPU",
  "memory": "$MEMORY"
}
EOF
)

echo -e "${BLUE}Updated task definition prepared.${NC}"
echo -e "${YELLOW}Health check configuration:${NC}"
echo "  Command: nc -z localhost 9090 || exit 1"
echo "  Interval: 30 seconds"
echo "  Timeout: 5 seconds"
echo "  Retries: 3"
echo "  Start Period: 60 seconds"

echo -e "${YELLOW}Command configuration:${NC}"
echo "  --web.external-url=/prometheus"
echo "  --web.route-prefix=/"

# Register new task definition if not in dry run mode
if [ "$DRY_RUN" = false ]; then
  echo -e "${BLUE}Registering new task definition...${NC}"

  # Save task definition to a temporary file
  TEMP_TASK_DEF_FILE=$(mktemp)
  echo "$UPDATED_TASK_DEF" > $TEMP_TASK_DEF_FILE

  # Register using the file
  NEW_TASK_DEF=$(aws ecs register-task-definition --cli-input-json "file://$TEMP_TASK_DEF_FILE" --region $AWS_REGION)
  REGISTER_RESULT=$?

  # Clean up the temporary file
  rm $TEMP_TASK_DEF_FILE

  if [ $REGISTER_RESULT -ne 0 ]; then
    echo -e "${RED}Error: Failed to register updated task definition.${NC}"
    exit 1
  fi

  NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEF | jq -r '.taskDefinition.taskDefinitionArn')
  echo -e "${GREEN}Registered new task definition: $NEW_TASK_DEF_ARN${NC}"

  # Update the service with the new task definition
  echo -e "${BLUE}Updating service to use new task definition...${NC}"
  UPDATE_RESULT=$(aws ecs update-service --cluster $CLUSTER --service $SERVICE --task-definition $NEW_TASK_DEF_ARN --region $AWS_REGION --force-new-deployment)
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to update service.${NC}"
    exit 1
  fi
  echo -e "${GREEN}Service updated successfully!${NC}"

  # Get the target group ARN
  TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names prometheus-tg --region $AWS_REGION --query 'TargetGroups[0].TargetGroupArn' --output text)
  if [ -z "$TARGET_GROUP_ARN" ]; then
    echo -e "${YELLOW}Warning: Could not find target group 'prometheus-tg'. No load balancer integration.${NC}"
  else
    echo -e "${GREEN}Found target group: $TARGET_GROUP_ARN${NC}"

    # Check existing load balancer configuration in the service
    HAS_LB=$(aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $AWS_REGION --query 'services[0].loadBalancers' --output text)

    if [ -z "$HAS_LB" ] || [ "$HAS_LB" == "None" ]; then
      echo -e "${YELLOW}Service doesn't have load balancer configuration. Would need to update infrastructure code.${NC}"
      echo -e "${YELLOW}Please update the Terraform/CDK code to include the load balancer target group.${NC}"
    else
      echo -e "${GREEN}Service already has load balancer configuration.${NC}"
    fi
  fi

  echo -e "${BLUE}Waiting for service to stabilize (this may take a few minutes)...${NC}"
  aws ecs wait services-stable --cluster $CLUSTER --services $SERVICE --region $AWS_REGION
  echo -e "${GREEN}Service has reached a steady state.${NC}"

  # Check the health of the service after update
  echo -e "${BLUE}Checking service health after update...${NC}"
  RUNNING_COUNT=$(aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $AWS_REGION --query "services[0].runningCount" --output text)
  DESIRED_COUNT=$(aws ecs describe-services --cluster $CLUSTER --services $SERVICE --region $AWS_REGION --query "services[0].desiredCount" --output text)

  if [ "$RUNNING_COUNT" -eq "$DESIRED_COUNT" ]; then
    echo -e "${GREEN}Service is running $RUNNING_COUNT/$DESIRED_COUNT tasks.${NC}"
  else
    echo -e "${YELLOW}Service is running $RUNNING_COUNT/$DESIRED_COUNT tasks. Not all tasks are running.${NC}"
  fi

  # Get the task ARN
  TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE --region $AWS_REGION --query 'taskArns[0]' --output text)
  if [ -n "$TASK_ARN" ] && [ "$TASK_ARN" != "None" ]; then
    echo -e "${BLUE}Checking container health status...${NC}"
    HEALTH_STATUS=$(aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN --region $AWS_REGION --query 'tasks[0].containers[0].healthStatus' --output text)

    if [ "$HEALTH_STATUS" == "HEALTHY" ]; then
      echo -e "${GREEN}Container health status: $HEALTH_STATUS${NC}"
    else
      echo -e "${YELLOW}Container health status: $HEALTH_STATUS${NC}"
      echo -e "${YELLOW}The container may still be starting up or have health check issues.${NC}"
    fi
  else
    echo -e "${YELLOW}No tasks found for service.${NC}"
  fi
else
  echo -e "${YELLOW}Dry run mode - no changes were made.${NC}"
  echo -e "${YELLOW}The task definition would have been updated with a health check and command configuration.${NC}"
  echo -e "${YELLOW}The service would have been updated to use the new task definition.${NC}"
fi

echo -e "${BLUE}Script completed.${NC}"
