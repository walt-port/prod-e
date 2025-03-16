#!/bin/bash

# Script to test connectivity to Prometheus service from an ECS task
# This helps diagnose if the Prometheus service is accessible within the ECS cluster

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing connectivity to Prometheus service...${NC}"

# Create log group if it doesn't exist
echo -e "${YELLOW}Creating log group if it doesn't exist...${NC}"
aws logs create-log-group --log-group-name "/ecs/prometheus-test-task" || true

# Create ECS task definition for testing
echo -e "${YELLOW}Creating temporary task definition for testing...${NC}"

cat > prometheus-test-task.json << EOF
{
  "family": "prometheus-test-task",
  "networkMode": "awsvpc",
  "executionRoleArn": "arn:aws:iam::043309339649:role/ecs-task-execution-role",
  "containerDefinitions": [
    {
      "name": "test-container",
      "image": "amazon/aws-cli:latest",
      "essential": true,
      "command": [
        "sh", "-c",
        "curl -v http://prod-e-prom-service:9090/api/v1/query?query=up || echo 'Failed to connect'; sleep 30"
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/prometheus-test-task",
          "awslogs-region": "us-west-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "cpu": "256",
  "memory": "512"
}
EOF

# Register the task definition
task_def_arn=$(aws ecs register-task-definition --cli-input-json file://prometheus-test-task.json | jq -r '.taskDefinition.taskDefinitionArn')

if [ -z "$task_def_arn" ]; then
  echo -e "${RED}Failed to register task definition.${NC}"
  exit 1
fi

echo -e "${GREEN}Task definition registered: $task_def_arn${NC}"

# Get subnet and security group
subnet_id=$(aws ecs describe-services --cluster prod-e-cluster --services grafana-service | jq -r '.services[0].networkConfiguration.awsvpcConfiguration.subnets[0]')
sg_id=$(aws ecs describe-services --cluster prod-e-cluster --services grafana-service | jq -r '.services[0].networkConfiguration.awsvpcConfiguration.securityGroups[0]')

# Run task
echo -e "${YELLOW}Running test task...${NC}"
task_arn=$(aws ecs run-task \
  --cluster prod-e-cluster \
  --task-definition prometheus-test-task \
  --network-configuration "awsvpcConfiguration={subnets=[$subnet_id],securityGroups=[$sg_id],assignPublicIp=DISABLED}" \
  --launch-type FARGATE | jq -r '.tasks[0].taskArn')

if [ -z "$task_arn" ]; then
  echo -e "${RED}Failed to start task.${NC}"
  exit 1
fi

echo -e "${GREEN}Task started: $task_arn${NC}"
task_id=$(echo $task_arn | awk -F'/' '{print $3}')

# Wait for task to complete
echo -e "${YELLOW}Waiting for task to complete...${NC}"
aws ecs wait tasks-stopped --cluster prod-e-cluster --tasks $task_id

# Get logs
echo -e "${YELLOW}Retrieving logs...${NC}"
sleep 10  # Give some time for logs to be available

# Get log stream name
log_stream=$(aws logs describe-log-streams \
  --log-group-name "/ecs/prometheus-test-task" \
  --log-stream-name-prefix "ecs/test-container/$task_id" \
  --max-items 1 | jq -r '.logStreams[0].logStreamName')

if [ -z "$log_stream" ] || [ "$log_stream" == "null" ]; then
  echo -e "${RED}No log stream found for task.${NC}"
  exit 1
fi

# Get logs from the stream
aws logs get-log-events --log-group-name "/ecs/prometheus-test-task" --log-stream-name "$log_stream" | jq -r '.events[].message'

# Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
aws ecs deregister-task-definition --task-definition prometheus-test-task:1 > /dev/null
rm prometheus-test-task.json

echo -e "${GREEN}Test completed.${NC}"
