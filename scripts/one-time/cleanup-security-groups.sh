#!/bin/bash
# Script to safely delete unused security groups
# This script will check if the security groups are being used
# before attempting to delete them

# Set to 1 for dry run mode (no actual deletion)
DRY_RUN=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Security groups to check and potentially delete
SECURITY_GROUPS=(
  "sg-0be700337c9fb39cf" # efs-mount-security-group
  "sg-0017d666e5148acac" # prom-security-group
  "sg-0a70331071c677329" # ecs-security-group
  "sg-095f444f62444fc95" # db-security-group
)

# Function to check if a security group has dependencies
check_dependencies() {
  local sg_id=$1
  local sg_name=$2

  echo -e "${YELLOW}Checking dependencies for ${sg_name} (${sg_id})...${NC}"

  # Check for ENI associations
  eni_count=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=${sg_id}" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text | wc -w)

  if [ $eni_count -gt 0 ]; then
    echo -e "${RED}Security group ${sg_name} (${sg_id}) is associated with ${eni_count} network interface(s).${NC}"
    echo -e "${YELLOW}Interfaces:${NC}"
    aws ec2 describe-network-interfaces --filters "Name=group-id,Values=${sg_id}" --query 'NetworkInterfaces[].{ID:NetworkInterfaceId,Description:Description,Status:Status}' --output table
    return 1
  fi

  # Check for references in other security groups' rules
  ref_count=$(aws ec2 describe-security-groups --query "SecurityGroups[?SecurityGroupId!='${sg_id}'].IpPermissions[].UserIdGroupPairs[?GroupId=='${sg_id}']" --output text | wc -l)

  if [ $ref_count -gt 0 ]; then
    echo -e "${RED}Security group ${sg_name} (${sg_id}) is referenced in ${ref_count} other security group rule(s).${NC}"
    echo -e "${YELLOW}Security groups referencing this group:${NC}"
    aws ec2 describe-security-groups --query "SecurityGroups[?SecurityGroupId!='${sg_id}' && contains(IpPermissions[].UserIdGroupPairs[].GroupId, '${sg_id}')].{ID:SecurityGroupId,Name:GroupName}" --output table
    return 1
  fi

  echo -e "${GREEN}Security group ${sg_name} (${sg_id}) has no dependencies.${NC}"
  return 0
}

# Function to delete a security group
delete_security_group() {
  local sg_id=$1
  local sg_name=$2

  if [ $DRY_RUN -eq 1 ]; then
    echo -e "${YELLOW}DRY RUN: Would delete security group ${sg_name} (${sg_id})${NC}"
    return 0
  fi

  echo -e "${YELLOW}Deleting security group ${sg_name} (${sg_id})...${NC}"

  if aws ec2 delete-security-group --group-id ${sg_id}; then
    echo -e "${GREEN}Successfully deleted security group ${sg_name} (${sg_id})${NC}"
    return 0
  else
    echo -e "${RED}Failed to delete security group ${sg_name} (${sg_id})${NC}"
    return 1
  fi
}

# Main execution
echo -e "${YELLOW}Starting security group cleanup check...${NC}"
echo -e "${YELLOW}Running in $([ $DRY_RUN -eq 1 ] && echo "DRY RUN" || echo "DELETION") mode${NC}"
echo ""

for sg_id in "${SECURITY_GROUPS[@]}"; do
  # Get security group name
  sg_name=$(aws ec2 describe-security-groups --group-ids ${sg_id} --query "SecurityGroups[0].GroupName" --output text 2>/dev/null)

  if [ -z "$sg_name" ] || [ "$sg_name" == "None" ]; then
    echo -e "${RED}Security group ${sg_id} not found.${NC}"
    continue
  fi

  echo -e "${YELLOW}==== Checking ${sg_name} (${sg_id}) ====${NC}"

  if check_dependencies ${sg_id} ${sg_name}; then
    delete_security_group ${sg_id} ${sg_name}
  else
    echo -e "${RED}Cannot delete security group ${sg_name} (${sg_id}) due to dependencies.${NC}"
  fi

  echo ""
done

echo -e "${GREEN}Security group cleanup check completed.${NC}"
echo -e "${YELLOW}To perform actual deletion, set DRY_RUN=0 in this script.${NC}"
