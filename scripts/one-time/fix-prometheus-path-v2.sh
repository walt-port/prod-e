#!/bin/bash

# Script to fix Prometheus URL prefix configuration - Version 2
# This script updates the command with web.external-url and web.route-prefix set to the same value

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Fixing Prometheus URL prefix configuration (V2)...${NC}"

# Get current task definition
echo -e "${YELLOW}Getting current task definition...${NC}"
aws ecs describe-task-definition --task-definition prom-task > prom-task-def.json

# Update task definition
echo -e "${YELLOW}Updating task definition command...${NC}"
jq '.taskDefinition.containerDefinitions[0].command = ["--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus", "--web.console.libraries=/usr/share/prometheus/console_libraries", "--web.console.templates=/usr/share/prometheus/consoles", "--web.external-url=/prometheus", "--web.route-prefix=/prometheus"]' prom-task-def.json > prom-task-def-updated.json

# Remove unnecessary fields
echo -e "${YELLOW}Preparing task definition for re-registration...${NC}"
jq 'del(.taskDefinition.taskDefinitionArn, .taskDefinition.revision, .taskDefinition.status, .taskDefinition.requiresAttributes, .taskDefinition.compatibilities, .taskDefinition.registeredAt, .taskDefinition.registeredBy)' prom-task-def-updated.json > prom-task-def-clean.json

# Extract the task definition part
jq '.taskDefinition' prom-task-def-clean.json > prom-task-def-final.json

# Register new task definition
echo -e "${YELLOW}Registering updated task definition...${NC}"
new_task_def=$(aws ecs register-task-definition --cli-input-json file://prom-task-def-final.json)
new_task_def_arn=$(echo $new_task_def | jq -r '.taskDefinition.taskDefinitionArn')

if [ -z "$new_task_def_arn" ]; then
  echo -e "${RED}Failed to register updated task definition.${NC}"
  rm prom-task-def*.json
  exit 1
fi

echo -e "${GREEN}New task definition registered: $new_task_def_arn${NC}"

# Update the service to use the new task definition
echo -e "${YELLOW}Updating Prometheus service to use new task definition...${NC}"
aws ecs update-service --cluster prod-e-cluster --service prod-e-prom-service --task-definition $new_task_def_arn --force-new-deployment

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully updated Prometheus service.${NC}"
else
  echo -e "${RED}Failed to update Prometheus service.${NC}"
  rm prom-task-def*.json
  exit 1
fi

# Clean up
rm prom-task-def*.json

echo -e "${GREEN}Prometheus URL prefix configuration update completed. The service will deploy a new task with the updated configuration.${NC}"
echo -e "${YELLOW}Wait a few minutes for the new task to start and stabilize before testing.${NC}"

# Also update the health check path for the target group
echo -e "${YELLOW}Updating health check path for the target group...${NC}"
tg_arn=$(aws elbv2 describe-target-groups --names prometheus-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 modify-target-group --target-group-arn $tg_arn --health-check-path "/prometheus/api/v1/query?query=up"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully updated target group health check path.${NC}"
else
  echo -e "${RED}Failed to update target group health check path.${NC}"
fi
