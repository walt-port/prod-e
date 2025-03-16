#!/bin/bash

# Script to fix Prometheus ALB routing configuration
# This script updates the ALB configuration to properly route to Prometheus

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Fixing Prometheus ALB routing configuration...${NC}"

# Get ALB ARN
alb_arn=$(aws elbv2 describe-load-balancers --names application-load-balancer --query 'LoadBalancers[0].LoadBalancerArn' --output text)
echo -e "ALB ARN: ${alb_arn}"

# Get Listener ARN
listener_arn=$(aws elbv2 describe-listeners --load-balancer-arn ${alb_arn} --query 'Listeners[0].ListenerArn' --output text)
echo -e "Listener ARN: ${listener_arn}"

# Get Prometheus Target Group ARN
prometheus_tg_arn=$(aws elbv2 describe-target-groups --names prometheus-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
echo -e "Prometheus Target Group ARN: ${prometheus_tg_arn}"

# Find Prometheus rule
prometheus_rule_arn=$(aws elbv2 describe-rules --listener-arn ${listener_arn} | jq -r '.Rules[] | select(.Actions[0].TargetGroupArn == "'${prometheus_tg_arn}'").RuleArn')

if [ -z "$prometheus_rule_arn" ]; then
  echo -e "${RED}No rule found for Prometheus target group.${NC}"
else
  echo -e "Prometheus Rule ARN: ${prometheus_rule_arn}"

  # Check the path patterns
  path_patterns=$(aws elbv2 describe-rules --rule-arns ${prometheus_rule_arn} | jq -r '.Rules[0].Conditions[0].PathPatternConfig.Values[]')
  echo -e "Current path patterns: ${path_patterns}"

  # Update rule if needed
  if echo "$path_patterns" | grep -q '/prometheus' && ! echo "$path_patterns" | grep -q '/prometheus/'; then
    echo -e "${YELLOW}Updating rule to add /prometheus/ path pattern...${NC}"

    aws elbv2 modify-rule \
      --rule-arn ${prometheus_rule_arn} \
      --conditions '[{"Field":"path-pattern","Values":["/prometheus","/prometheus/*","/prometheus/"]}]' \
      --actions '[{"Type":"forward","TargetGroupArn":"'${prometheus_tg_arn}'"}]'

    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Successfully updated rule.${NC}"
    else
      echo -e "${RED}Failed to update rule.${NC}"
    fi
  else
    echo -e "${GREEN}Rule path patterns look correct.${NC}"
  fi
fi

# Check health check settings for Prometheus target group
health_check=$(aws elbv2 describe-target-group-attributes --target-group-arn ${prometheus_tg_arn} | jq '.Attributes[] | select(.Key | contains("healthcheck"))')
echo -e "${YELLOW}Current health check settings:${NC}"
echo "${health_check}" | jq -r '.Key + ": " + .Value'

# Update health check settings if needed
echo -e "${YELLOW}Updating health check settings...${NC}"
aws elbv2 modify-target-group \
  --target-group-arn ${prometheus_tg_arn} \
  --health-check-protocol HTTP \
  --health-check-port 9090 \
  --health-check-path "/api/v1/query?query=up" \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 10 \
  --healthy-threshold-count 3 \
  --unhealthy-threshold-count 3

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully updated health check settings.${NC}"
else
  echo -e "${RED}Failed to update health check settings.${NC}"
fi

echo -e "${GREEN}Prometheus ALB configuration update completed.${NC}"
