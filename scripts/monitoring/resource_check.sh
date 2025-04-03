#!/bin/bash

# Resource Check Script for Production Experience Showcase (v2 - Dynamic)
# This script dynamically checks the status of AWS resources tagged for the project.

# --- Configuration ---
# Attempt to read from .env, but provide defaults
if [ -f .env ]; then
  # Use process substitution and grep/sed for safer parsing
  while IFS='=' read -r key value; do
    # Skip empty lines or lines without =
    [[ -z "$key" || -z "$value" ]] && continue
    # Remove potential surrounding quotes from value
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^\'//" -e "s/\'$//")
    # Export valid variable names
    if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      export "$key=$value"
    fi
  done < <(grep -v '^[[:space:]]*#' .env | grep '=') # Filter comments/empty lines and lines without =
fi

# Use AWS_REGION from env or default
AWS_REGION=${AWS_REGION:-"us-west-2"}
# Use PROJECT_NAME from env or default (important for tagging)
PROJECT_NAME=${PROJECT_NAME:-"prod-e"}

# ANSI color codes (Corrected definition)
C_RESET=$(echo -e '\033[0m')
C_BLUE=$(echo -e '\033[0;34m')
C_GREEN=$(echo -e '\033[0;32m')
C_RED=$(echo -e '\033[0;31m')
C_YELLOW=$(echo -e '\033[0;33m')
C_GRAY=$(echo -e '\033[0;90m')
C_BOLD_BLUE=$(echo -e '\033[1;34m')
C_BOLD_WHITE=$(echo -e '\033[1;37m')

# Symbols
S_TICK="✓"
S_CROSS="✗"
S_INFO="ℹ"
S_ARROW="→"
S_WARN="⚠"

# Counters
TOTAL_CHECKS=0
CHECKS_PASSED=0
CHECKS_FAILED=0

# CSV output option
CSV_OUTPUT=false
CSV_FILE="resource_check_results_${PROJECT_NAME}.csv"

# --- Helper Functions ---

# Print script banner
print_banner() {
    echo -e "${C_BOLD_BLUE}=====================================================${C_RESET}"
    echo -e "${C_BOLD_BLUE}    ${C_BOLD_WHITE}PRODUCTION EXPERIENCE RESOURCE CHECK (${PROJECT_NAME})${C_RESET} ${C_BOLD_BLUE}"
    echo -e "${C_BOLD_BLUE}=====================================================${C_RESET}"
    echo -e "Starting check at $(date)"
    echo -e "${C_GRAY}Region: $AWS_REGION | Project Tag: Project=$PROJECT_NAME${C_RESET}\\n"
}

# Print section header
print_header() {
    echo -e "\\n${C_BLUE}======== $1 ========${C_RESET}"
    if [ "$CSV_OUTPUT" = true ]; then
        echo "Section,$1" >> "$CSV_FILE"
    fi
}

# Base print function
print_message() {
    local color=$1
    local symbol=$2
    local type=$3 # For CSV
    local message=$4
    echo -e "${color}${symbol} ${message}${C_RESET}"
    if [ "$CSV_OUTPUT" = true ]; then
        # Basic CSV escaping (replace comma with semicolon)
        message_csv=$(echo "$message" | sed 's/,/;/g')
        echo "$type,${symbol} ${message_csv}" >> "$CSV_FILE"
    fi
}

# Print success message
print_success() {
    ((TOTAL_CHECKS++))
    ((CHECKS_PASSED++))
    print_message "$C_GREEN" "$S_TICK" "Success" "$1"
}

# Print error message
print_error() {
    ((TOTAL_CHECKS++))
    ((CHECKS_FAILED++))
    print_message "$C_RED" "$S_CROSS" "Error" "$1"
}

# Print warning/info message
print_info() {
    # Info messages don't count towards total checks
    print_message "$C_YELLOW" "$S_INFO" "Info" "$1"
}

# Print detail message (indented gray text)
print_detail() {
    # Detail messages don't count towards total checks
    echo -e "${C_GRAY}  ${S_ARROW} $1${C_RESET}"
    if [ "$CSV_OUTPUT" = true ]; then
        message_csv=$(echo "$1" | sed 's/,/;/g')
        echo "Detail,  ${S_ARROW} ${message_csv}" >> "$CSV_FILE"
    fi
}

# Print warning message
print_warning() {
    # Warnings don't count towards total checks but use yellow
    print_message "$C_YELLOW" "$S_WARN" "Warning" "$1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --csv) CSV_OUTPUT=true ;;
        --output=*) CSV_FILE="${1#*=}" ; CSV_OUTPUT=true ;;
        --help|-h)
            echo "Usage: $0 [--csv] [--output=FILENAME]"
            echo "Options:"
            echo "  --csv             Output results to CSV file (default: resource_check_results_${PROJECT_NAME}.csv)"
            echo "  --output=FILENAME Output results to specified CSV file (implies --csv)"
            echo "  --help, -h        Display this help message"
            echo "Reads AWS_REGION and PROJECT_NAME from .env file if present, or uses defaults."
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# --- Initial Checks ---
# Check dependencies
if ! command_exists aws; then
    echo -e "${C_RED}Error: AWS CLI is not installed or not in PATH.${C_RESET}"
    exit 1
fi
if ! command_exists jq; then
    echo -e "${C_RED}Error: jq is not installed or not in PATH.${C_RESET}"
    exit 1
fi

# Initialize CSV file if needed
if [ "$CSV_OUTPUT" = true ]; then
    echo "Type,Message" > "$CSV_FILE"
    echo "CSV output will be written to $CSV_FILE"
fi

# Print Banner
print_banner

# --- Check Functions ---

# Check AWS CLI configuration and identity
check_aws_config() {
    print_header "AWS CONFIGURATION"
    IDENTITY=$(aws sts get-caller-identity --output json --region "$AWS_REGION" 2>&1)
    if [ $? -ne 0 ]; then
        print_error "AWS CLI call failed. Is it configured correctly?"
        print_detail "$IDENTITY" # Show error message
        exit 1
    else
        ACCOUNT_ID=$(echo "$IDENTITY" | jq -r '.Account')
        USER_ARN=$(echo "$IDENTITY" | jq -r '.Arn')
        print_success "AWS CLI configured"
        print_detail "Account ID: $ACCOUNT_ID"
        print_detail "User ARN: $USER_ARN"
        print_detail "Region: $AWS_REGION"
    fi
}

# Check VPC and networking resources based on Project tag
check_vpc() {
    print_header "VPC & NETWORKING (Project: $PROJECT_NAME)"
    VPC_INFO=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT_NAME" --query "Vpcs[0].{VpcId:VpcId, CidrBlock:CidrBlock, State:State}" --output json --region "$AWS_REGION" 2>/dev/null)

    if [ -z "$VPC_INFO" ] || [ "$(echo "$VPC_INFO" | jq -r '.VpcId')" == "null" ]; then
        print_error "VPC with tag Project=$PROJECT_NAME not found."
        return 1 # Indicate failure to calling function if needed
    fi

    VPC_ID=$(echo "$VPC_INFO" | jq -r '.VpcId')
    VPC_CIDR=$(echo "$VPC_INFO" | jq -r '.CidrBlock')
    VPC_STATE=$(echo "$VPC_INFO" | jq -r '.State')

    if [ "$VPC_STATE" == "available" ]; then
        print_success "VPC found: $VPC_ID ($VPC_CIDR) - State: $VPC_STATE"
    else
        print_error "VPC found but not available: $VPC_ID ($VPC_CIDR) - State: $VPC_STATE"
    fi

    # Check Subnets
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].{SubnetId:SubnetId, CidrBlock:CidrBlock, AvailabilityZone:AvailabilityZone, TagName:Tags[?Key=='Name']|[0].Value}" --output json --region "$AWS_REGION")
    SUBNET_COUNT=$(echo "$SUBNETS" | jq '. | length')
    if [ "$SUBNET_COUNT" -eq 0 ]; then
        print_error "No subnets found in VPC $VPC_ID"
    else
        print_success "Found $SUBNET_COUNT subnets in VPC $VPC_ID"
        echo "$SUBNETS" | jq -c '.[]' | while read -r subnet; do
            SUBNET_ID=$(echo "$subnet" | jq -r '.SubnetId')
            SUBNET_CIDR=$(echo "$subnet" | jq -r '.CidrBlock')
            SUBNET_AZ=$(echo "$subnet" | jq -r '.AvailabilityZone')
            SUBNET_NAME=$(echo "$subnet" | jq -r '.TagName // "N/A"')
            print_detail "Subnet: $SUBNET_NAME ($SUBNET_ID), CIDR: $SUBNET_CIDR, AZ: $SUBNET_AZ"
        done
    fi

    # Check Internet Gateway
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text --region "$AWS_REGION")
    if [[ "$IGW_ID" == "None" || -z "$IGW_ID" ]]; then
        print_error "No Internet Gateway attached to VPC $VPC_ID"
    else
        print_success "Internet Gateway found: $IGW_ID"
    fi

    # Check NAT Gateways
    NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[*].{NatGatewayId:NatGatewayId,State:State,SubnetId:SubnetId}" --output json --region "$AWS_REGION")
    NAT_COUNT=$(echo "$NAT_GATEWAYS" | jq '. | length')
    if [ "$NAT_COUNT" -eq 0 ]; then
        print_warning "No NAT Gateways found in VPC $VPC_ID (This might be intentional)"
    else
        print_success "Found $NAT_COUNT NAT Gateway(s) in VPC $VPC_ID"
        echo "$NAT_GATEWAYS" | jq -c '.[]' | while read -r nat; do
            NAT_ID=$(echo "$nat" | jq -r '.NatGatewayId')
            NAT_STATE=$(echo "$nat" | jq -r '.State')
            NAT_SUBNET=$(echo "$nat" | jq -r '.SubnetId')
            if [ "$NAT_STATE" == "available" ]; then
                 print_detail "NAT Gateway: $NAT_ID in $NAT_SUBNET - State: $NAT_STATE"
            else
                 print_warning "NAT Gateway: $NAT_ID in $NAT_SUBNET - State: $NAT_STATE"
            fi
        done
    fi

    # Check Security Groups (only those tagged with the project)
    SEC_GROUPS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Project,Values=$PROJECT_NAME" --query "SecurityGroups[*].{GroupId:GroupId,GroupName:GroupName,Description:Description}" --output json --region "$AWS_REGION")
    SG_COUNT=$(echo "$SEC_GROUPS" | jq '. | length')
     if [ "$SG_COUNT" -eq 0 ]; then
      print_error "No Security Groups tagged with Project=$PROJECT_NAME found in VPC $VPC_ID"
    else
      print_success "Found $SG_COUNT Security Group(s) tagged with Project=$PROJECT_NAME"
      echo "$SEC_GROUPS" | jq -c '.[]' | while read -r sg; do
          SG_ID=$(echo "$sg" | jq -r '.GroupId')
          SG_NAME=$(echo "$sg" | jq -r '.GroupName')
          SG_DESC=$(echo "$sg" | jq -r '.Description')
          print_detail "Security Group: $SG_NAME ($SG_ID) - $SG_DESC"
       done
    fi
}

# Check RDS resources based on Project tag
check_rds() {
    print_header "RDS DATABASE (Project: $PROJECT_NAME)"
    # Use resourcegroupstaggingapi for reliable tag-based discovery
    DB_ARN=$(aws resourcegroupstaggingapi get-resources --resource-type-filters rds:db --tag-filters Key=Project,Values="$PROJECT_NAME" --query 'ResourceTagMappingList[0].ResourceARN' --output text --region "$AWS_REGION" 2>/dev/null)

    if [ -z "$DB_ARN" ]; then
        print_error "RDS Instance with tag Project=$PROJECT_NAME not found via tagging API."
        return 1
    fi

    # Describe using the discovered ARN (more precisely, the identifier extracted from ARN)
    DB_ID=$(echo "$DB_ARN" | awk -F: '{print $NF}')
    DB_INSTANCE_INFO=$(aws rds describe-db-instances --db-instance-identifier "$DB_ID" --query "DBInstances[0].{DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceStatus:DBInstanceStatus,Endpoint:Endpoint.Address,Port:Endpoint.Port,Engine:Engine,DBInstanceClass:DBInstanceClass}" --output json --region "$AWS_REGION" 2>/dev/null)

    if [ -z "$DB_INSTANCE_INFO" ] || [ "$(echo "$DB_INSTANCE_INFO" | jq -r '.DBInstanceIdentifier // "null"')" == "null" ]; then
        print_error "Failed to describe RDS Instance $DB_ID found via ARN $DB_ARN."
        return 1
    fi

    DB_STATUS=$(echo "$DB_INSTANCE_INFO" | jq -r '.DBInstanceStatus')
    DB_ENDPOINT=$(echo "$DB_INSTANCE_INFO" | jq -r '.Endpoint // "N/A"')
    DB_PORT=$(echo "$DB_INSTANCE_INFO" | jq -r '.Port // "N/A"')
    DB_ENGINE=$(echo "$DB_INSTANCE_INFO" | jq -r '.Engine')
    DB_CLASS=$(echo "$DB_INSTANCE_INFO" | jq -r '.DBInstanceClass')

    if [ "$DB_STATUS" == "available" ]; then
        print_success "RDS Instance: $DB_ID ($DB_ENGINE $DB_CLASS)"
        print_detail "Status: $DB_STATUS"
        print_detail "Endpoint: $DB_ENDPOINT:$DB_PORT"
    else
        print_error "RDS Instance: $DB_ID ($DB_ENGINE $DB_CLASS) - Status: $DB_STATUS"
    fi

    # Check DB subnet group (assuming one based on naming convention)
    SUBNET_GROUP_NAME="${PROJECT_NAME}-rds-subnet-group"
    SUBNET_GROUP_STATUS=$(aws rds describe-db-subnet-groups --db-subnet-group-name "$SUBNET_GROUP_NAME" --query "DBSubnetGroups[0].SubnetGroupStatus" --output text --region "$AWS_REGION" 2>/dev/null)
    if [ -z "$SUBNET_GROUP_STATUS" ]; then
        print_error "DB Subnet Group '$SUBNET_GROUP_NAME' not found."
    else
        print_success "DB Subnet Group: $SUBNET_GROUP_NAME - Status: $SUBNET_GROUP_STATUS"
    fi
}

# Check ECS resources based on Project tag
check_ecs() {
    print_header "ECS CLUSTER & SERVICES (Project: $PROJECT_NAME)"
    # Find cluster using tags - Simplified and safer approach
    CLUSTER_ARN=""
    ALL_CLUSTERS=$(aws ecs list-clusters --query clusterArns --output json --region "$AWS_REGION")
    for arn in $(echo "$ALL_CLUSTERS" | jq -r '.[]'); do
      TAGS=$(aws ecs describe-clusters --clusters "$arn" --include TAGS --query "clusters[0].tags" --output json --region "$AWS_REGION" 2>/dev/null)
      PROJECT_TAG_VAL=$(echo "$TAGS" | jq -r --arg proj "$PROJECT_NAME" '.[] | select(.key=="Project" and .value==$proj) | .value')
      if [ "$PROJECT_TAG_VAL" == "$PROJECT_NAME" ]; then
        CLUSTER_ARN="$arn"
        CLUSTER_ARN_GLOBAL="$arn" # Set global variable
        break
      fi
    done

    if [ -z "$CLUSTER_ARN" ]; then
        print_error "ECS Cluster tagged with Project=$PROJECT_NAME not found."
        CLUSTER_ARN_GLOBAL="" # Ensure global is empty if not found
        return 1
    fi

    CLUSTER_INFO=$(aws ecs describe-clusters --clusters "$CLUSTER_ARN" --query "clusters[0].{clusterName:clusterName, status:status, runningTasksCount:runningTasksCount, pendingTasksCount:pendingTasksCount, activeServicesCount:activeServicesCount}" --output json --region "$AWS_REGION")
    CLUSTER_NAME=$(echo "$CLUSTER_INFO" | jq -r '.clusterName')
    CLUSTER_STATUS=$(echo "$CLUSTER_INFO" | jq -r '.status')
    RUNNING_TASKS=$(echo "$CLUSTER_INFO" | jq -r '.runningTasksCount')
    PENDING_TASKS=$(echo "$CLUSTER_INFO" | jq -r '.pendingTasksCount')
    ACTIVE_SERVICES=$(echo "$CLUSTER_INFO" | jq -r '.activeServicesCount')

    if [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
        print_success "ECS Cluster: $CLUSTER_NAME - Status: $CLUSTER_STATUS"
        print_detail "$ACTIVE_SERVICES Active Services | $RUNNING_TASKS Running Tasks | $PENDING_TASKS Pending Tasks"
    else
        print_error "ECS Cluster: $CLUSTER_NAME - Status: $CLUSTER_STATUS"
    fi

    # Check ECS Services within the cluster tagged with the project
    SERVICES=$(aws ecs list-services --cluster "$CLUSTER_ARN" --query "serviceArns" --output json --region "$AWS_REGION")
    if [ "$(echo "$SERVICES" | jq '. | length')" -eq 0 ]; then
        print_warning "No services found in cluster $CLUSTER_NAME."
    else
        print_success "Checking services in cluster $CLUSTER_NAME..."
        SERVICE_ARNS=$(echo "$SERVICES" | jq -r '.[]')
        echo "$SERVICE_ARNS" | while read -r service_arn; do
            # Describe service and check tag separately for simplicity/robustness
            SERVICE_TAGS=$(aws ecs describe-services --cluster "$CLUSTER_ARN" --services "$service_arn" --include TAGS --query "services[0].tags" --output json --region "$AWS_REGION" 2>/dev/null)
            PROJECT_TAG_VAL=$(echo "$SERVICE_TAGS" | jq -r --arg proj "$PROJECT_NAME" '.[] | select(.key=="Project" and .value==$proj) | .value')

            # Only process if the Project tag matches
            if [ "$PROJECT_TAG_VAL" == "$PROJECT_NAME" ]; then
                SERVICE_DETAIL=$(aws ecs describe-services --cluster "$CLUSTER_ARN" --services "$service_arn" --query "services[0].{serviceName:serviceName,status:status,desiredCount:desiredCount,runningCount:runningCount,taskDefinition:taskDefinition}" --output json --region "$AWS_REGION")
                SERVICE_NAME=$(echo "$SERVICE_DETAIL" | jq -r '.serviceName')
                SERVICE_STATUS=$(echo "$SERVICE_DETAIL" | jq -r '.status')
                DESIRED_COUNT=$(echo "$SERVICE_DETAIL" | jq -r '.desiredCount')
                RUNNING_COUNT=$(echo "$SERVICE_DETAIL" | jq -r '.runningCount')
                TASK_DEF_ARN=$(echo "$SERVICE_DETAIL" | jq -r '.taskDefinition')
                TASK_DEF_FAMILY=$(echo "$TASK_DEF_ARN" | awk -F/ '{print $2}' | awk -F: '{print $1}')

                if [[ "$SERVICE_STATUS" == "ACTIVE" && "$DESIRED_COUNT" == "$RUNNING_COUNT" ]]; then
                    print_success "Service: $SERVICE_NAME - Status: $SERVICE_STATUS ($RUNNING_COUNT/$DESIRED_COUNT tasks)"
                    print_detail "Task Definition Family: $TASK_DEF_FAMILY"
                elif [[ "$SERVICE_STATUS" == "ACTIVE" ]]; then
                     print_warning "Service: $SERVICE_NAME - Status: $SERVICE_STATUS ($RUNNING_COUNT/$DESIRED_COUNT tasks rolling/deploying?)"
                     print_detail "Task Definition Family: $TASK_DEF_FAMILY"
                else
                    print_error "Service: $SERVICE_NAME - Status: $SERVICE_STATUS ($RUNNING_COUNT/$DESIRED_COUNT tasks)"
                    print_detail "Task Definition Family: $TASK_DEF_FAMILY"
                fi
            fi
        done
    fi
}

# Check ALB resources based on Project tag
check_alb() {
    print_header "APPLICATION LOAD BALANCER (Project: $PROJECT_NAME)"
    ALB_ARN=""
    # Try finding via tags first
    ALB_ARN=$(aws resourcegroupstaggingapi get-resources --resource-type-filters elasticloadbalancing:loadbalancer --tag-filters Key=Project,Values="$PROJECT_NAME" --query 'ResourceTagMappingList[?contains(ResourceARN, ":loadbalancer/app/")][0].ResourceARN' --output text --region "$AWS_REGION" 2>/dev/null)

    # Fallback: Try finding via name convention if tags didn't work
    if [ -z "$ALB_ARN" ]; then
        print_info "ALB not found via tags, trying name: ${PROJECT_NAME}-alb"
        ALB_ARN=$(aws elbv2 describe-load-balancers --names "${PROJECT_NAME}-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text --region "$AWS_REGION" 2>/dev/null)
    fi

    if [ -z "$ALB_ARN" ]; then
        print_error "Application Load Balancer for project $PROJECT_NAME not found via tags or name."
        return 1
    fi

    # Describe using the discovered ARN
    ALB_INFO=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" --query "LoadBalancers[0].{LoadBalancerArn:LoadBalancerArn,LoadBalancerName:LoadBalancerName,DNSName:DNSName,State:State.Code,Type:Type}" --output json --region "$AWS_REGION" 2>/dev/null)

    if [ -z "$ALB_INFO" ] || [ "$(echo "$ALB_INFO" | jq -r '.LoadBalancerArn // "null"')" == "null" ]; then
        print_error "Failed to describe ALB found via ARN $ALB_ARN."
        return 1
    fi

    ALB_NAME=$(echo "$ALB_INFO" | jq -r '.LoadBalancerName')
    ALB_DNS=$(echo "$ALB_INFO" | jq -r '.DNSName')
    ALB_STATE=$(echo "$ALB_INFO" | jq -r '.State')
    ALB_TYPE=$(echo "$ALB_INFO" | jq -r '.Type')

    # Set global variables for other functions (Added)
    ALB_ARN_GLOBAL="$ALB_ARN"
    ALB_DNS_GLOBAL="$ALB_DNS"

    if [ "$ALB_STATE" == "active" ]; then
        print_success "ALB: $ALB_NAME ($ALB_TYPE) - State: $ALB_STATE"
        print_detail "DNS: $ALB_DNS"
    else
        print_error "ALB: $ALB_NAME ($ALB_TYPE) - State: $ALB_STATE"
        print_detail "DNS: $ALB_DNS"
    fi

    # Check Target Groups associated with this ALB
    TARGET_GROUPS=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --query "TargetGroups[*].{TargetGroupArn:TargetGroupArn,TargetGroupName:TargetGroupName,Port:Port,Protocol:Protocol,TargetType:TargetType}" --output json --region "$AWS_REGION")
    TG_COUNT=$(echo "$TARGET_GROUPS" | jq '. | length')

    if [ "$TG_COUNT" -eq 0 ]; then
        print_error "No Target Groups found for ALB $ALB_NAME"
    else
        print_success "Found $TG_COUNT Target Group(s) for ALB $ALB_NAME"
        echo "$TARGET_GROUPS" | jq -c '.[]' | while read -r tg; do
            TG_ARN=$(echo "$tg" | jq -r '.TargetGroupArn')
            TG_NAME=$(echo "$tg" | jq -r '.TargetGroupName')
            TG_PORT=$(echo "$tg" | jq -r '.Port')
            TG_PROTO=$(echo "$tg" | jq -r '.Protocol')
            TG_TYPE=$(echo "$tg" | jq -r '.TargetType')
            print_detail "Target Group: $TG_NAME ($TG_PROTO:$TG_PORT, $TG_TYPE)"

            # Check Target Health
            TARGETS_HEALTH=$(aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --query "TargetHealthDescriptions[*].{TargetId:Target.Id,TargetPort:Target.Port,TargetHealth:TargetHealth.State}" --output json --region "$AWS_REGION")
            TARGET_COUNT=$(echo "$TARGETS_HEALTH" | jq '. | length')

            if [ "$TARGET_COUNT" -eq 0 ]; then
                print_warning "  ${S_ARROW} $TG_NAME: No targets registered"
            else
                 echo "$TARGETS_HEALTH" | jq -c '.[]' | while read -r target_health; do
                    T_ID=$(echo "$target_health" | jq -r '.TargetId')
                    T_PORT=$(echo "$target_health" | jq -r '.TargetPort // "N/A"') # Handle potential null port
                    T_STATE=$(echo "$target_health" | jq -r '.TargetHealth')
                    TARGET_STR="Target $T_ID"
                    if [ "$T_PORT" != "N/A" ]; then TARGET_STR="$TARGET_STR:$T_PORT"; fi

                    if [ "$T_STATE" == "healthy" ]; then
                        print_detail "  ${S_ARROW} $TARGET_STR - $T_STATE ${C_GREEN}${S_TICK}${C_GRAY}"
                    elif [ "$T_STATE" == "draining" ] || [ "$T_STATE" == "initial" ]; then
                        print_detail "  ${S_ARROW} $TARGET_STR - $T_STATE ${C_YELLOW}${S_INFO}${C_GRAY}"
                    else
                        print_detail "  ${S_ARROW} $TARGET_STR - $T_STATE ${C_RED}${S_CROSS}${C_GRAY}"
                        ((CHECKS_FAILED++)) # Count unhealthy target as a failure for summary
                    fi
                done
            fi
        done
    fi
}

# Check ECR repositories used by project tasks
check_ecr() {
    print_header "ECR REPOSITORIES (Used by Project: $PROJECT_NAME)"

    # Find task def families for the project
    FAMILIES=$(aws ecs list-task-definition-families --family-prefix "$PROJECT_NAME" --status ACTIVE --query "families" --output json --region "$AWS_REGION" 2>/dev/null)
    if [ $? -ne 0 ] || [ "$(echo "$FAMILIES" | jq '. | length')" -eq 0 ]; then
        print_warning "No active task definition families found with prefix '$PROJECT_NAME'. Unable to check ECR Repos."
        return
    fi

    REPOSITORIES=""
    # Use process substitution to avoid subshell for the outer loop
    while read -r family; do
      # Get only the latest ACTIVE revision ARN for the family
      TASK_DEF_ARN=$(aws ecs describe-task-definition --task-definition "$family" --query 'taskDefinition.taskDefinitionArn' --output text --region "$AWS_REGION" 2>/dev/null)
      if [ -z "$TASK_DEF_ARN" ]; then
          print_warning "Could not get ARN for task definition family $family, skipping ECR check for it."
          continue
      fi

      # Describe the specific task definition ARN
      TASK_DEF_DETAIL=$(aws ecs describe-task-definition --task-definition "$TASK_DEF_ARN" --query 'taskDefinition' --output json --region "$AWS_REGION" 2>/dev/null)
      if [ -z "$TASK_DEF_DETAIL" ]; then
          print_warning "Could not describe task definition $TASK_DEF_ARN, skipping ECR check for it."
          continue
      fi

      # Extract image URIs from container definitions
      IMAGES=$(echo "$TASK_DEF_DETAIL" | jq -r '.containerDefinitions[].image')
      for img in $IMAGES; do
          # Extract repo name: Look for content between first / and :
          REPO_NAME=$(echo "$img" | awk -F/ '{print $2}' | awk -F: '{print $1}')
          # Check if valid repo name was extracted
          if [[ -n "$REPO_NAME" && "$REPO_NAME" != *"amazonaws.com"* ]]; then
              # Add to list if not already present
              if ! echo "$REPOSITORIES" | grep -qw "$REPO_NAME"; then
                  REPOSITORIES="$REPOSITORIES $REPO_NAME"
              fi
          fi
      done
    done < <(echo "$FAMILIES" | jq -r '.[]') # Feed families to the loop

    if [ -z "$REPOSITORIES" ]; then
        print_warning "Could not extract any repository names from active task definitions."
        return
    fi

    print_success "Checking ECR repositories derived from task definitions..."
    MISSING_REPOS=0
    for repo in $REPOSITORIES; do
        # Trim potential leading/trailing whitespace just in case
        repo=$(echo "$repo" | xargs)
        if [ -z "$repo" ]; then continue; fi

        aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" --output text > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            print_error "ECR Repository: '$repo' not found."
            ((MISSING_REPOS++))
        else
            print_detail "ECR Repository: '$repo' found ${C_GREEN}${S_TICK}${C_GRAY}"
        fi
    done

    if [ $MISSING_REPOS -eq 0 ]; then
        print_success "All derived ECR repositories found."
    else
        print_error "$MISSING_REPOS derived ECR repository/repositories missing."
    fi
}

# Check status of ECS Task Definitions
check_ecs_task_definitions() {
    print_header "ECS TASK DEFINITIONS (Prefix: $PROJECT_NAME)"
    FAMILIES=$(aws ecs list-task-definition-families --family-prefix "$PROJECT_NAME" --status ACTIVE --query "families" --output json --region "$AWS_REGION" 2>/dev/null)

    if [ $? -ne 0 ] || [ "$(echo "$FAMILIES" | jq '. | length')" -eq 0 ]; then
        print_error "No ACTIVE task definition families found with prefix '$PROJECT_NAME'."
        return 1
    fi

    print_success "Found active task definition families matching prefix '$PROJECT_NAME'. Checking status..."
    FAILED_DEFS=0
    while read -r family; do
        # Get the latest revision ARN of the active family
        TASK_DEF_ARN=$(aws ecs describe-task-definition --task-definition "$family" --query 'taskDefinition.taskDefinitionArn' --output text --region "$AWS_REGION" 2>/dev/null)
        if [ -z "$TASK_DEF_ARN" ]; then
            print_warning "Could not get ARN for task definition family $family, cannot check status."
            continue
        fi

        # Describe using the ARN to ensure we check the specific latest active revision
        TASK_DEF_STATUS=$(aws ecs describe-task-definition --task-definition "$TASK_DEF_ARN" --query 'taskDefinition.status' --output text --region "$AWS_REGION" 2>/dev/null)

        if [ "$TASK_DEF_STATUS" == "ACTIVE" ]; then
            print_detail "Task Definition: $family (Latest: $TASK_DEF_ARN) - Status: $TASK_DEF_STATUS ${C_GREEN}${S_TICK}${C_GRAY}"
        else
            print_error "Task Definition: $family (Latest: $TASK_DEF_ARN) - Status: $TASK_DEF_STATUS"
            ((FAILED_DEFS++))
        fi
    done < <(echo "$FAMILIES" | jq -r '.[]')

    if [ $FAILED_DEFS -eq 0 ]; then
        print_success "All latest active task definitions have ACTIVE status."
    else
        print_error "$FAILED_DEFS task definition(s) found with non-ACTIVE status."
    fi
}

# Check monitoring services (Grafana, Prometheus ECS Services)
check_monitoring() {
    print_header "MONITORING SERVICES (ECS)"

    # Use global variable set by check_alb
    if [ -z "$ALB_DNS_GLOBAL" ]; then
        print_warning "ALB DNS not available, skipping endpoint checks."
        # ALB_DNS="" # Ensure it's empty # This line is not needed
    fi

    # Use CLUSTER_ARN_GLOBAL
    if [ -z "$CLUSTER_ARN_GLOBAL" ]; then
      print_error "Cluster ARN not available, cannot check monitoring services."
      return 1
    fi

    # Check Grafana Service (assuming name convention *-grafana-service)
    GRAFANA_SERVICE_ARN=$(aws ecs list-services --cluster "$CLUSTER_ARN_GLOBAL" --query "serviceArns[?contains(@, \`$PROJECT_NAME-grafana-service\`)]" --output text --region "$AWS_REGION")
    if [ -z "$GRAFANA_SERVICE_ARN" ]; then
        print_error "Grafana ECS service not found (expected name like '$PROJECT_NAME-grafana-service')."
    else
        SERVICE_DETAIL=$(aws ecs describe-services --cluster "$CLUSTER_ARN_GLOBAL" --services "$GRAFANA_SERVICE_ARN" --query "services[0].{serviceName:serviceName,status:status,desiredCount:desiredCount,runningCount:runningCount}" --output json --region "$AWS_REGION")
        # ... (rest of service status check like in check_ecs) ...
        SERVICE_NAME=$(echo "$SERVICE_DETAIL" | jq -r '.serviceName')
        SERVICE_STATUS=$(echo "$SERVICE_DETAIL" | jq -r '.status')
        DESIRED_COUNT=$(echo "$SERVICE_DETAIL" | jq -r '.desiredCount')
        RUNNING_COUNT=$(echo "$SERVICE_DETAIL" | jq -r '.runningCount')
        if [[ "$SERVICE_STATUS" == "ACTIVE" && "$DESIRED_COUNT" == "$RUNNING_COUNT" ]]; then
             print_success "$SERVICE_NAME: Status ACTIVE ($RUNNING_COUNT/$DESIRED_COUNT tasks)"
        else
             print_error "$SERVICE_NAME: Status $SERVICE_STATUS ($RUNNING_COUNT/$DESIRED_COUNT tasks)"
        fi

        # Check Grafana endpoint if ALB DNS is known
        print_info "Skipping external endpoint check for Grafana (use ECS/TG health)."
    fi

    # Check Prometheus Service (assuming name convention *-prometheus-service)
    PROM_SERVICE_ARN=$(aws ecs list-services --cluster "$CLUSTER_ARN_GLOBAL" --query "serviceArns[?contains(@, \`$PROJECT_NAME-prometheus-service\`)]" --output text --region "$AWS_REGION")
     if [ -z "$PROM_SERVICE_ARN" ]; then
        print_error "Prometheus ECS service not found (expected name like '$PROJECT_NAME-prometheus-service')."
    else
        SERVICE_DETAIL=$(aws ecs describe-services --cluster "$CLUSTER_ARN_GLOBAL" --services "$PROM_SERVICE_ARN" --query "services[0].{serviceName:serviceName,status:status,desiredCount:desiredCount,runningCount:runningCount}" --output json --region "$AWS_REGION")
        # ... (rest of service status check like in check_ecs) ...
        SERVICE_NAME=$(echo "$SERVICE_DETAIL" | jq -r '.serviceName')
        SERVICE_STATUS=$(echo "$SERVICE_DETAIL" | jq -r '.status')
        DESIRED_COUNT=$(echo "$SERVICE_DETAIL" | jq -r '.desiredCount')
        RUNNING_COUNT=$(echo "$SERVICE_DETAIL" | jq -r '.runningCount')
         if [[ "$SERVICE_STATUS" == "ACTIVE" && "$DESIRED_COUNT" == "$RUNNING_COUNT" ]]; then
             print_success "$SERVICE_NAME: Status ACTIVE ($RUNNING_COUNT/$DESIRED_COUNT tasks)"
        else
             print_error "$SERVICE_NAME: Status $SERVICE_STATUS ($RUNNING_COUNT/$DESIRED_COUNT tasks)"
        fi

        # Check Prometheus endpoint if ALB DNS is known
        print_info "Skipping external endpoint check for Prometheus (use ECS/TG health)."
    fi
}

# NEW: Check ALB Listener Rules
check_alb_listener_rules() {
    # Use global variable set by check_alb
    if [ -z "$ALB_ARN_GLOBAL" ]; then
        print_info "Skipping Listener Rule check as ALB ARN is not available."
        return
    fi

    print_header "ALB LISTENER RULES (ALB: ${ALB_ARN_GLOBAL})"


    # Treat port as number in query
    LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN_GLOBAL" --query "Listeners[0].ListenerArn" --output text --region "$AWS_REGION" 2>/dev/null)

    if [[ "$LISTENER_ARN" == "None" || -z "$LISTENER_ARN" ]]; then
        print_error "No listener found on port $listener_port for ALB."
        return 1
    fi

    print_success "Found Listener: $LISTENER_ARN (Port $listener_port)"
    LISTENER_RULES=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules" --output json --region "$AWS_REGION" 2>/dev/null)
    if [ $? -ne 0 ]; then
      print_error "Failed to describe rules for listener $LISTENER_ARN."
      return 1
    fi
    RULES_COUNT=$(echo "$LISTENER_RULES" | jq '. | length')

    if [ "$RULES_COUNT" -eq 0 ]; then
        print_error "No rules found for listener $LISTENER_ARN"
    else
        print_success "Found $RULES_COUNT rules for listener $LISTENER_ARN. Verifying project rules..."

        # Rule Checks Logic
        declare -A rule_checks
        rule_checks=( [5]=0 [10]=0 [20]=0 [100]=0 ) # Expected priorities
        declare -A rule_details

        # Use process substitution to read rules safely
        while IFS= read -r rule; do
            PRIORITY=$(echo "$rule" | jq -r '.Priority | select(. != "default")')
            IS_DEFAULT=$(echo "$rule" | jq -r '.IsDefault')
            # Check if Conditions and Actions exist before trying to access them
            HAS_CONDITIONS=$(echo "$rule" | jq 'has("Conditions")')
            HAS_ACTIONS=$(echo "$rule" | jq 'has("Actions") and (.Actions | length > 0)')

            if [ "$IS_DEFAULT" == "true" ]; then continue; fi # Skip default rule

            # Basic structural checks
            if [[ "$HAS_ACTIONS" != "true" || -z "$PRIORITY" ]]; then continue; fi

            ACTION_TYPE=$(echo "$rule" | jq -r '.Actions[0].Type')
            TARGET_GROUP_ARN=$(echo "$rule" | jq -r '.Actions[0].TargetGroupArn // ""')

            if [[ "$ACTION_TYPE" != "forward" || -z "$TARGET_GROUP_ARN" ]]; then continue; fi

            # Store details using priority as key
            rule_details[$PRIORITY]=$(echo "$rule" | jq -c '{Conditions: .Conditions, TargetGroupArn: .Actions[0].TargetGroupArn}')

            # Mark priority as found
            if [[ -v rule_checks[$PRIORITY] ]]; then
                rule_checks[$PRIORITY]=1
            fi
        done < <(echo "$LISTENER_RULES" | jq -c '.[]')

        # --- Verify specific rules ---
        # Rule Priority 5: Frontend App (/* -> app-tg)
        ((TOTAL_CHECKS++))
        local CHECK_PASSED=false
        if [ ${rule_checks[5]} -eq 1 ]; then
            DETAILS_JSON=${rule_details[5]}
            COND_PATH=$(echo "$DETAILS_JSON" | jq -r '.Conditions[0].PathPatternConfig.Values[0] // ""')
            COND_FIELD=$(echo "$DETAILS_JSON" | jq -r '.Conditions[0].Field // ""')
            TG_ARN=$(echo "$DETAILS_JSON" | jq -r '.TargetGroupArn // ""')
            if [[ "$COND_FIELD" == "path-pattern" && "$COND_PATH" == "/*" && "$TG_ARN" == *"app-tg"* ]]; then
                 print_detail "Rule Prio 5 (App): Path '$COND_PATH' -> TG '$TG_ARN' ${C_GREEN}${S_TICK}${C_GRAY}"
                 CHECK_PASSED=true
                 ((CHECKS_PASSED++))
            fi
        fi
        if [ "$CHECK_PASSED" = false ]; then
            print_error "Rule Prio 5 (App): Missing or incorrect config. Expected '/* -> *app-tg*' Found: $(echo ${rule_details[5]:-MISSING} | jq -c .)"
            ((CHECKS_FAILED++))
        fi

        # Rule Priority 10: Grafana (/grafana* -> grafana-tg)
        ((TOTAL_CHECKS++))
        CHECK_PASSED=false
        if [ ${rule_checks[10]} -eq 1 ]; then
            DETAILS_JSON=${rule_details[10]}
            COND_PATH=$(echo "$DETAILS_JSON" | jq -r '.Conditions[0].PathPatternConfig.Values[0] // ""')
            COND_FIELD=$(echo "$DETAILS_JSON" | jq -r '.Conditions[0].Field // ""')
            TG_ARN=$(echo "$DETAILS_JSON" | jq -r '.TargetGroupArn // ""')
            if [[ "$COND_FIELD" == "path-pattern" && "$COND_PATH" == *"/grafana"* && "$TG_ARN" == *"grafana-tg"* ]]; then
                 print_detail "Rule Prio 10 (Grafana): Path '$COND_PATH' -> TG '$TG_ARN' ${C_GREEN}${S_TICK}${C_GRAY}"
                 CHECK_PASSED=true
                 ((CHECKS_PASSED++))
            fi
        fi
         if [ "$CHECK_PASSED" = false ]; then
            print_error "Rule Prio 10 (Grafana): Missing or incorrect config. Expected '*/grafana* -> *grafana-tg*' Found: $(echo ${rule_details[10]:-MISSING} | jq -c .)"
            ((CHECKS_FAILED++))
        fi

        # Rule Priority 20: Prometheus (/metrics* -> prometheus-tg)
        ((TOTAL_CHECKS++))
         CHECK_PASSED=false
        if [ ${rule_checks[20]} -eq 1 ]; then
            DETAILS_JSON=${rule_details[20]}
            COND_PATH=$(echo "$DETAILS_JSON" | jq -r '.Conditions[0].PathPatternConfig.Values[0] // ""')
             COND_FIELD=$(echo "$DETAILS_JSON" | jq -r '.Conditions[0].Field // ""')
            TG_ARN=$(echo "$DETAILS_JSON" | jq -r '.TargetGroupArn // ""')
            if [[ "$COND_FIELD" == "path-pattern" && "$COND_PATH" == *"/metrics"* && "$TG_ARN" == *"prometheus-tg"* ]]; then
                 print_detail "Rule Prio 20 (Prometheus): Path '$COND_PATH' -> TG '$TG_ARN' ${C_GREEN}${S_TICK}${C_GRAY}"
                  CHECK_PASSED=true
                 ((CHECKS_PASSED++))
            fi
        fi
         if [ "$CHECK_PASSED" = false ]; then
            print_error "Rule Prio 20 (Prometheus): Missing or incorrect config. Expected '*/metrics* -> *prometheus-tg*' Found: $(echo ${rule_details[20]:-MISSING} | jq -c .)"
            ((CHECKS_FAILED++))
        fi

        # Rule Priority 100: Backend (/api/* -> ecs-tg)
        ((TOTAL_CHECKS++))
         CHECK_PASSED=false
        if [ ${rule_checks[100]} -eq 1 ]; then
            DETAILS_JSON=${rule_details[100]}
            COND_PATH=$(echo "$DETAILS_JSON" | jq -r '.Conditions[0].PathPatternConfig.Values[0] // ""')
             COND_FIELD=$(echo "$DETAILS_JSON" | jq -r '.Conditions[0].Field // ""')
            TG_ARN=$(echo "$DETAILS_JSON" | jq -r '.TargetGroupArn // ""')
            if [[ "$COND_FIELD" == "path-pattern" && "$COND_PATH" == "/api/*" && "$TG_ARN" == *"ecs-tg"* ]]; then
                 print_detail "Rule Prio 100 (Backend): Path '$COND_PATH' -> TG '$TG_ARN' ${C_GREEN}${S_TICK}${C_GRAY}"
                  CHECK_PASSED=true
                 ((CHECKS_PASSED++))
            fi
        fi
         if [ "$CHECK_PASSED" = false ]; then
            print_error "Rule Prio 100 (Backend): Missing or incorrect config. Expected '/api/* -> *ecs-tg*' Found: $(echo ${rule_details[100]:-MISSING} | jq -c .)"
            ((CHECKS_FAILED++))
        fi
    fi # End if rules count > 0
}

# --- Main Execution ---

# Run AWS config check first
check_aws_config

# Global variables for shared info
CLUSTER_ARN_GLOBAL=\"\" # Set by check_ecs
ALB_ARN_GLOBAL=\"\"     # Set by check_alb
ALB_DNS_GLOBAL=\"\"     # Set by check_alb

# Get Cluster ARN once for efficiency # This block seems redundant now
# Ensure this happens *before* check_ecs and check_monitoring are called
# CLUSTER_ARN=\"\" # Remove
# ... (remove old cluster ARN finding logic here if present) ...

# Run checks for core components
check_vpc
check_rds
check_ecs # Combined cluster and service check
check_ecr # Added
check_ecs_task_definitions # Added
check_alb # Sets ALB_ARN_GLOBAL, ALB_DNS_GLOBAL
check_alb_listener_rules # Added Call - Uses ALB_ARN_GLOBAL
check_monitoring # Uses CLUSTER_ARN_GLOBAL and ALB_DNS_GLOBAL

# --- Summary ---
print_header "CHECK SUMMARY"
if [ "$CHECKS_FAILED" -eq 0 ]; then
    print_message "$C_GREEN" "$S_TICK" "Summary" "All $TOTAL_CHECKS checks passed."
else
    print_message "$C_RED" "$S_CROSS" "Summary" "$CHECKS_FAILED out of $TOTAL_CHECKS checks reported errors or warnings needing attention."
fi
echo -e "${C_BOLD_BLUE}=====================================================${C_RESET}"
echo -e "${C_BOLD_BLUE}                 CHECK COMPLETE                    ${C_RESET}"
echo -e "${C_BOLD_BLUE}=====================================================${C_RESET}\\n"

# Exit with status code based on failures
if [ "$CHECKS_FAILED" -gt 0 ]; then
    exit 1
else
    exit 0
fi
