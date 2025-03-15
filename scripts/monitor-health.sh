#!/bin/bash

# Service Health Monitoring Script for Production Experience Showcase
# This script checks the health of critical services and can send alerts

# Set AWS region
AWS_REGION="us-west-2"

# ANSI color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ALERTS_ENABLED=${ALERTS_ENABLED:-false}
SLACK_WEBHOOK=${SLACK_WEBHOOK:-""}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}
CHECK_INTERVAL=${CHECK_INTERVAL:-300}  # Default: 5 minutes

# Print usage information
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Monitor the health of Production Experience Showcase services"
  echo ""
  echo "Options:"
  echo "  -a, --alerts            Enable alerts via Slack and/or email"
  echo "  -s, --slack URL         Slack webhook URL for notifications"
  echo "  -e, --email ADDRESS     Email address for notifications"
  echo "  -i, --interval SECONDS  Check interval in seconds (default: 300)"
  echo "  -o, --once              Run checks once and exit"
  echo "  -h, --help              Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --once                       Run health check once"
  echo "  $0 --alerts --slack https://hooks.slack.com/... --interval 600  Run every 10 minutes with Slack alerts"
}

# Process command line arguments
RUN_ONCE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--alerts)
      ALERTS_ENABLED=true
      shift
      ;;
    -s|--slack)
      SLACK_WEBHOOK="$2"
      shift 2
      ;;
    -e|--email)
      EMAIL_RECIPIENT="$2"
      shift 2
      ;;
    -i|--interval)
      CHECK_INTERVAL="$2"
      shift 2
      ;;
    -o|--once)
      RUN_ONCE=true
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

# Validate configuration if alerts are enabled
if [ "$ALERTS_ENABLED" = true ]; then
  if [ -z "$SLACK_WEBHOOK" ] && [ -z "$EMAIL_RECIPIENT" ]; then
    echo "Error: Alerts are enabled but no notification method specified."
    echo "Please provide a Slack webhook URL or email address."
    usage
    exit 1
  fi
fi

# Function to send a Slack alert
send_slack_alert() {
  local message="$1"
  local color="$2"  # good, warning, danger

  if [ -z "$SLACK_WEBHOOK" ]; then
    return
  fi

  curl -s -X POST -H 'Content-type: application/json' \
    --data "{\"attachments\":[{\"color\":\"$color\",\"text\":\"$message\"}]}" \
    "$SLACK_WEBHOOK" > /dev/null
}

# Function to send an email alert
send_email_alert() {
  local subject="$1"
  local message="$2"

  if [ -z "$EMAIL_RECIPIENT" ]; then
    return
  fi

  echo "$message" | mail -s "$subject" "$EMAIL_RECIPIENT"
}

# Function to send alerts
send_alert() {
  local message="$1"
  local severity="$2"  # critical, warning, info

  if [ "$ALERTS_ENABLED" != true ]; then
    return
  fi

  # Format timestamp
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local formatted_message="[$timestamp] $message"

  # Set appropriate colors and subjects based on severity
  local slack_color="good"
  local email_subject="[INFO] Prod-E Health Monitor"

  if [ "$severity" = "warning" ]; then
    slack_color="warning"
    email_subject="[WARNING] Prod-E Health Monitor"
  elif [ "$severity" = "critical" ]; then
    slack_color="danger"
    email_subject="[CRITICAL] Prod-E Health Monitor"
  fi

  # Send alerts
  if [ -n "$SLACK_WEBHOOK" ]; then
    send_slack_alert "$formatted_message" "$slack_color"
  fi

  if [ -n "$EMAIL_RECIPIENT" ]; then
    send_email_alert "$email_subject" "$formatted_message"
  fi
}

# Check ECS services
check_ecs_services() {
  echo -e "\n${BLUE}Checking ECS Services...${NC}"

  # Get ECS services
  SERVICES=$(aws ecs list-services --cluster prod-e-cluster --output text --region $AWS_REGION --query "serviceArns")

  if [[ -z "$SERVICES" ]]; then
    echo -e "${RED}No ECS services found${NC}"
    send_alert "No ECS services found in prod-e-cluster" "critical"
    return
  fi

  local has_errors=false

  for service in $SERVICES; do
    SERVICE_DATA=$(aws ecs describe-services --cluster prod-e-cluster --services $service --output text --region $AWS_REGION --query "services[*].[serviceName,status,desiredCount,runningCount]")
    echo "$SERVICE_DATA" | while read -r name status desired running; do
      echo -n "Service $name: "

      if [[ "$status" != "ACTIVE" ]]; then
        echo -e "${RED}NOT ACTIVE ($status)${NC}"
        send_alert "ECS service $name is not active ($status)" "critical"
        has_errors=true
      elif [[ "$running" -lt "$desired" ]]; then
        echo -e "${YELLOW}DEGRADED ($running/$desired tasks running)${NC}"
        send_alert "ECS service $name is degraded ($running/$desired tasks running)" "warning"
        has_errors=true
      else
        echo -e "${GREEN}HEALTHY ($running/$desired tasks running)${NC}"
      fi
    done
  done

  if [ "$has_errors" = false ]; then
    echo -e "${GREEN}All ECS services are healthy${NC}"
  fi
}

# Check RDS instances
check_rds() {
  echo -e "\n${BLUE}Checking RDS Instances...${NC}"

  # Get DB instances
  DB_INSTANCES=$(aws rds describe-db-instances --output text --region $AWS_REGION --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]")

  if [[ -z "$DB_INSTANCES" ]]; then
    echo -e "${YELLOW}No RDS instances found${NC}"
    return
  fi

  local has_errors=false

  echo "$DB_INSTANCES" | while read -r id status; do
    echo -n "Database $id: "

    if [[ "$status" == "available" ]]; then
      echo -e "${GREEN}HEALTHY ($status)${NC}"
    else
      echo -e "${RED}PROBLEM ($status)${NC}"
      send_alert "RDS instance $id is not available ($status)" "critical"
      has_errors=true
    fi
  done

  if [ "$has_errors" = false ]; then
    echo -e "${GREEN}All RDS instances are healthy${NC}"
  fi
}

# Check application load balancers
check_alb() {
  echo -e "\n${BLUE}Checking Load Balancers...${NC}"

  # Get ALBs
  ALBS=$(aws elbv2 describe-load-balancers --output text --region $AWS_REGION --query "LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]")

  if [[ -z "$ALBS" ]]; then
    echo -e "${YELLOW}No Application Load Balancers found${NC}"
    return
  fi

  local has_errors=false

  echo "$ALBS" | while read -r name dns state; do
    echo -n "Load balancer $name: "

    if [[ "$state" == "active" ]]; then
      echo -e "${GREEN}HEALTHY ($state)${NC}"

      # Check target groups
      ALB_ARN=$(aws elbv2 describe-load-balancers --names "$name" --query "LoadBalancers[0].LoadBalancerArn" --output text --region $AWS_REGION)
      TARGET_GROUPS=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --output text --region $AWS_REGION --query "TargetGroups[*].[TargetGroupName,TargetGroupArn]")

      if [[ -n "$TARGET_GROUPS" ]]; then
        echo "$TARGET_GROUPS" | while read -r tg_name tg_arn; do
          # Check target health
          HEALTH=$(aws elbv2 describe-target-health --target-group-arn "$tg_arn" --output text --region $AWS_REGION --query "TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]")

          if [[ -z "$HEALTH" ]]; then
            echo -e "  Target group $tg_name: ${YELLOW}NO TARGETS${NC}"
          else
            local unhealthy=false
            echo "$HEALTH" | while read -r target state; do
              if [[ "$state" != "healthy" ]]; then
                echo -e "  Target $target: ${RED}$state${NC}"
                send_alert "Target $target in target group $tg_name is $state" "warning"
                unhealthy=true
              else
                echo -e "  Target $target: ${GREEN}$state${NC}"
              fi
            done

            if [ "$unhealthy" = false ]; then
              echo -e "  Target group $tg_name: ${GREEN}All targets healthy${NC}"
            fi
          fi
        done
      fi
    else
      echo -e "${RED}PROBLEM ($state)${NC}"
      send_alert "Load balancer $name is not active ($state)" "critical"
      has_errors=true
    fi
  done

  if [ "$has_errors" = false ]; then
    echo -e "${GREEN}All load balancers are healthy${NC}"
  fi
}

# Check endpoint health
check_endpoints() {
  echo -e "\n${BLUE}Checking Endpoints...${NC}"

  # Define endpoints to check with expected status code and timeout
  # format: "name|url|expected_status|timeout_seconds"
  local endpoints=(
    "Backend API|http://prod-e-api.internal/health|200|5"
    "Grafana|http://prod-e-grafana.internal/api/health|200|5"
    "Prometheus|http://prod-e-prometheus.internal/-/healthy|200|5"
  )

  local has_errors=false

  for endpoint in "${endpoints[@]}"; do
    IFS='|' read -r name url expected_status timeout <<< "$endpoint"
    echo -n "Endpoint $name ($url): "

    # Use curl to check the endpoint
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "TIMEOUT")

    if [[ "$response" == "TIMEOUT" ]]; then
      echo -e "${RED}TIMEOUT after ${timeout}s${NC}"
      send_alert "Endpoint $name ($url) timed out after ${timeout}s" "critical"
      has_errors=true
    elif [[ "$response" == "$expected_status" ]]; then
      echo -e "${GREEN}HEALTHY (HTTP $response)${NC}"
    else
      echo -e "${RED}PROBLEM (HTTP $response, expected $expected_status)${NC}"
      send_alert "Endpoint $name ($url) returned HTTP $response (expected $expected_status)" "critical"
      has_errors=true
    fi
  done

  if [ "$has_errors" = false ]; then
    echo -e "${GREEN}All endpoints are healthy${NC}"
  fi
}

# Run all health checks
run_health_checks() {
  echo -e "\n${BLUE}=======================================${NC}"
  echo -e "${BLUE}   PRODUCTION EXPERIENCE HEALTH CHECK  ${NC}"
  echo -e "${BLUE}=======================================${NC}"
  echo -e "Time: $(date)"
  echo -e "Alert notifications: $(if [ "$ALERTS_ENABLED" = true ]; then echo "Enabled"; else echo "Disabled"; fi)"

  check_ecs_services
  check_rds
  check_alb
  check_endpoints

  echo -e "\n${BLUE}=======================================${NC}"
  echo -e "${BLUE}         HEALTH CHECK COMPLETE         ${NC}"
  echo -e "${BLUE}=======================================${NC}\n"
}

# Main execution
if [ "$RUN_ONCE" = true ]; then
  # Run checks once
  run_health_checks
else
  # Run in a loop with the specified interval
  while true; do
    run_health_checks
    echo "Next check in $CHECK_INTERVAL seconds..."
    sleep $CHECK_INTERVAL
  done
fi
