#!/bin/bash
# Script to identify and clean up unused security groups
# This script helps identify which security groups are actually used and which can be safely deleted

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=true
PROJECT_TAG="prod-e"
AWS_REGION="us-west-2"

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
    --project=*)
      PROJECT_TAG="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --force           Actually delete security groups (default is dry run)"
      echo "  --region=NAME     Specify the AWS region (default: us-west-2)"
      echo "  --project=NAME    Project tag to filter security groups (default: prod-e)"
      echo "  --help            Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}=== Security Group Cleanup Tool ===${NC}"
echo "Project Tag: $PROJECT_TAG"
if $DRY_RUN; then
  echo -e "${YELLOW}Mode: Dry Run (no security groups will be deleted)${NC}"
  echo "Use --force to actually delete security groups"
else
  echo -e "${RED}Mode: Force (security groups will be deleted)${NC}"
fi

# Check AWS CLI configuration
echo -e "\n${BLUE}Checking AWS CLI configuration...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$ACCOUNT_ID" ]; then
  echo -e "${RED}Error: AWS CLI is not configured correctly${NC}"
  exit 1
fi
echo -e "${GREEN}AWS CLI configured for account: $ACCOUNT_ID${NC}"

# Get all security groups for the project
echo -e "\n${BLUE}Getting all security groups for project ${PROJECT_TAG}...${NC}"
SECURITY_GROUPS=$(aws ec2 describe-security-groups --filter Name=tag:Project,Values=$PROJECT_TAG --region $AWS_REGION | jq -r '.SecurityGroups[] | [.GroupId, .GroupName] | @tsv')

if [ -z "$SECURITY_GROUPS" ]; then
  echo -e "${YELLOW}No security groups found for project $PROJECT_TAG${NC}"
  exit 0
fi

# Count security groups
SG_COUNT=$(echo "$SECURITY_GROUPS" | wc -l)
echo -e "Found $SG_COUNT security groups for project $PROJECT_TAG"

# Check which security groups are actually in use
echo -e "\n${BLUE}Checking which security groups are in use...${NC}"

# Initialize arrays
declare -a USED_SGS
declare -a UNUSED_SGS
declare -a DEFAULT_SGS

while IFS=$'\t' read -r SG_ID SG_NAME; do
  echo -e "Checking security group: ${YELLOW}$SG_NAME ($SG_ID)${NC}"

  # Check if this is a default security group (can't be deleted)
  if [[ "$SG_NAME" == "default" ]]; then
    echo -e "  ${BLUE}This is a default VPC security group (can't be deleted)${NC}"
    DEFAULT_SGS+=("$SG_ID")
    continue
  fi

  # Check different services that might be using the security group

  # Check EC2 instances
  EC2_USAGE=$(aws ec2 describe-instances --filters "Name=instance.group-id,Values=$SG_ID" --query "Reservations[*].Instances[*].[InstanceId]" --output text --region $AWS_REGION)

  # Check ELBs
  ELB_USAGE=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?SecurityGroups[?contains(@, '$SG_ID')]].LoadBalancerName" --output text --region $AWS_REGION 2>/dev/null || echo "")

  # Check ALBs/NLBs
  ALB_USAGE=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?SecurityGroups[?contains(@, '$SG_ID')]].LoadBalancerArn" --output text --region $AWS_REGION 2>/dev/null || echo "")

  # Check RDS instances
  RDS_USAGE=$(aws rds describe-db-instances --query "DBInstances[?VpcSecurityGroups[?VpcSecurityGroupId=='$SG_ID']].DBInstanceIdentifier" --output text --region $AWS_REGION 2>/dev/null || echo "")

  # Check ECS services - do this more carefully
  SERVICES=$(aws ecs list-services --cluster prod-e-cluster --region $AWS_REGION --query 'serviceArns[]' --output text 2>/dev/null || echo "")
  ECS_USAGE=""
  if [ -n "$SERVICES" ]; then
    # Split the service ARNs by whitespace and process individually
    for SERVICE in $SERVICES; do
      SERVICE_NAME=$(echo $SERVICE | awk -F'/' '{print $3}')
      SERVICE_CHECK=$(aws ecs describe-services --cluster prod-e-cluster --services $SERVICE_NAME --region $AWS_REGION --query "services[?networkConfiguration.awsvpcConfiguration.securityGroups[?contains(@, '$SG_ID')]].serviceName" --output text 2>/dev/null || echo "")
      if [ -n "$SERVICE_CHECK" ]; then
        if [ -n "$ECS_USAGE" ]; then
          ECS_USAGE="$ECS_USAGE $SERVICE_CHECK"
        else
          ECS_USAGE="$SERVICE_CHECK"
        fi
      fi
    done
  fi

  # Check Lambda functions
  LAMBDA_USAGE=$(aws lambda list-functions --query "Functions[?VpcConfig.SecurityGroupIds[?contains(@, '$SG_ID')]].FunctionName" --output text --region $AWS_REGION 2>/dev/null || echo "")

  # Check if security group is referenced by another security group rule
  SG_RULE_USAGE=$(aws ec2 describe-security-groups --region $AWS_REGION --query "SecurityGroups[?IpPermissions[?UserIdGroupPairs[?GroupId=='$SG_ID']]].GroupId" --output text 2>/dev/null || echo "")

  if [ -n "$EC2_USAGE" ] || [ -n "$ELB_USAGE" ] || [ -n "$ALB_USAGE" ] || [ -n "$RDS_USAGE" ] || [ -n "$ECS_USAGE" ] || [ -n "$LAMBDA_USAGE" ] || [ -n "$SG_RULE_USAGE" ]; then
    echo -e "  ${GREEN}Security group is in use:${NC}"
    [ -n "$EC2_USAGE" ] && echo -e "    - EC2 instances: $EC2_USAGE"
    [ -n "$ELB_USAGE" ] && echo -e "    - Classic load balancers: $ELB_USAGE"
    [ -n "$ALB_USAGE" ] && echo -e "    - Application/Network load balancers: $ALB_USAGE"
    [ -n "$RDS_USAGE" ] && echo -e "    - RDS instances: $RDS_USAGE"
    [ -n "$ECS_USAGE" ] && echo -e "    - ECS services: $ECS_USAGE"
    [ -n "$LAMBDA_USAGE" ] && echo -e "    - Lambda functions: $LAMBDA_USAGE"
    [ -n "$SG_RULE_USAGE" ] && echo -e "    - Referenced by security groups: $SG_RULE_USAGE"
    USED_SGS+=("$SG_ID")
  else
    echo -e "  ${RED}Security group is not in use${NC}"
    UNUSED_SGS+=("$SG_ID")
  fi
done <<< "$SECURITY_GROUPS"

# Summarize findings
echo -e "\n${BLUE}Security Group Analysis Summary:${NC}"
echo -e "Total security groups: $SG_COUNT"
echo -e "Default security groups (can't delete): ${#DEFAULT_SGS[@]}"
echo -e "Security groups in use: ${#USED_SGS[@]}"
echo -e "Unused security groups: ${#UNUSED_SGS[@]}"

# Process unused security groups
if [ ${#UNUSED_SGS[@]} -gt 0 ]; then
  echo -e "\n${BLUE}Unused security groups that can be deleted:${NC}"
  for SG_ID in "${UNUSED_SGS[@]}"; do
    SG_NAME=$(aws ec2 describe-security-groups --group-ids $SG_ID --query "SecurityGroups[0].GroupName" --output text --region $AWS_REGION)
    echo -e "${YELLOW}$SG_NAME ($SG_ID)${NC}"

    if ! $DRY_RUN; then
      echo -e "  ${RED}Deleting security group...${NC}"
      aws ec2 delete-security-group --group-id $SG_ID --region $AWS_REGION
      if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}Successfully deleted security group $SG_ID${NC}"
      else
        echo -e "  ${RED}Failed to delete security group $SG_ID${NC}"
      fi
    else
      echo -e "  ${YELLOW}Would delete security group (dry run)${NC}"
    fi
  done
else
  echo -e "\n${GREEN}No unused security groups found${NC}"
fi

echo -e "\n${BLUE}Security group cleanup process completed.${NC}"
if $DRY_RUN; then
  echo -e "${YELLOW}This was a DRY RUN. No security groups were actually deleted.${NC}"
  echo "Use --force flag to perform actual deletion."
fi

exit 0
