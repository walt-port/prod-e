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
      TAGS=$(aws ecs describe-clusters --clusters "$arn" --include TAGS --query "clusters[0].tags" --output json --region "$AWS_REGION")
      PROJECT_TAG_VAL=$(echo "$TAGS" | jq -r --arg proj "$PROJECT_NAME" '.[] | select(.key=="Project" and .value==$proj) | .value')
      if [ "$PROJECT_TAG_VAL" == "$PROJECT_NAME" ]; then
        CLUSTER_ARN="$arn"
        break
      fi
    done

    if [ -z "$CLUSTER_ARN" ]; then
        print_error "ECS Cluster tagged with Project=$PROJECT_NAME not found."
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
        export CHECK_ALB_DNS=""
        return 1
    fi

    # Describe using the discovered ARN
    ALB_INFO=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" --query "LoadBalancers[0].{LoadBalancerArn:LoadBalancerArn,LoadBalancerName:LoadBalancerName,DNSName:DNSName,State:State.Code,Type:Type}" --output json --region "$AWS_REGION" 2>/dev/null)

    if [ -z "$ALB_INFO" ] || [ "$(echo "$ALB_INFO" | jq -r '.LoadBalancerArn // "null"')" == "null" ]; then
        print_error "Failed to describe ALB found via ARN $ALB_ARN."
        export CHECK_ALB_DNS=""
        return 1
    fi

    ALB_NAME=$(echo "$ALB_INFO" | jq -r '.LoadBalancerName')
    ALB_DNS=$(echo "$ALB_INFO" | jq -r '.DNSName')
    ALB_STATE=$(echo "$ALB_INFO" | jq -r '.State')
    ALB_TYPE=$(echo "$ALB_INFO" | jq -r '.Type')

    # Export the DNS name FOUND before potential errors below
    export CHECK_ALB_DNS="$ALB_DNS"

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
    FAMILIES=$(aws ecs list-task-definition-families --family-prefix "$PROJECT_NAME" --status ACTIVE --query "families" --output json --region "$AWS_REGION")
    if [ "$(echo "$FAMILIES" | jq '. | length')" -eq 0 ]; then
        print_warning "No active task definition families found with prefix '$PROJECT_NAME'."
        return
    fi

    IMAGE_URIS=""
    # Use process substitution to avoid subshell for the outer loop
    while read -r family; do
      TASK_DEF_DETAIL=$(aws ecs describe-task-definition --task-definition "$family" --query "taskDefinition" --output json --region "$AWS_REGION" 2>/dev/null)
      if [ -z "$TASK_DEF_DETAIL" ]; then
          print_warning "Could not describe task definition for $family, skipping."
          continue
      fi

      # Use process substitution for the inner loop as well
      while IFS= read -r img; do
        # Append the image URI followed by a newline directly to the main variable
        IMAGE_URIS+="${img}"$'\n'
      done < <(echo "$TASK_DEF_DETAIL" | jq -r '.containerDefinitions[].image')

    done < <(echo "$FAMILIES" | jq -r '.[]') # <--- Process substitution here

    # Get unique image URIs using printf and filter out empty lines
    UNIQUE_IMAGE_URIS=$(printf '%s' "$IMAGE_URIS" | sort -u | grep '.')

    if [ -z "$UNIQUE_IMAGE_URIS" ]; then
        print_error "Could not extract valid image URIs (format: registry/repo:tag) from latest task definitions."
        return
    fi

    print_success "Checking ECR repositories referenced in task definitions..."
    ALL_REPOS_OK=true
    FAILURE_DETAILS=""

    echo "$UNIQUE_IMAGE_URIS" | while read -r image_uri; do
        # Simpler parsing using parameter expansion and rev
        repo_tag=$(echo "$image_uri" | rev | cut -d/ -f1 | rev) # Get repo:tag part
        REPO_NAME=$(echo "$repo_tag" | cut -d: -f1)
        IMAGE_TAG=$(echo "$repo_tag" | cut -d: -f2)

        if [[ -z "$REPO_NAME" || -z "$IMAGE_TAG" || "$repo_tag" == "$REPO_NAME" ]]; then # Basic validation
            print_warning "Skipping potentially malformed image URI: $image_uri"
            continue
        fi

        # Check if repository exists
        REPO_URI=$(aws ecr describe-repositories --repository-names "$REPO_NAME" --query "repositories[0].repositoryUri" --output text --region "$AWS_REGION" 2>/dev/null)
        if [ $? -ne 0 ] || [ -z "$REPO_URI" ]; then
            print_error "Repository '$REPO_NAME' referenced in task definition not found."
            ALL_REPOS_OK=false
            FAILURE_DETAILS+="  ${S_ARROW} Repo missing: $REPO_NAME\\n"
            continue
        fi

        print_success "Repository: $REPO_NAME"
        print_detail "URI: $REPO_URI"

        # Check if the specific tag used exists
        IMAGE_DETAIL=$(aws ecr describe-images --repository-name "$REPO_NAME" --image-ids "imageTag=$IMAGE_TAG" --query "imageDetails[0].imagePushedAt" --output text --region "$AWS_REGION" 2>/dev/null)
        if [ $? -ne 0 ] || [ -z "$IMAGE_DETAIL" ]; then
            print_error "  Image tag '$IMAGE_TAG' used in task definition not found in repository '$REPO_NAME'."
            ALL_REPOS_OK=false
            FAILURE_DETAILS+="  ${S_ARROW} Tag missing: $REPO_NAME:$IMAGE_TAG\\n"
        else
            print_success "  Image tag '$IMAGE_TAG' found (Pushed at: $IMAGE_DETAIL)"
        fi
    done

    # Final status based on checks
    if [ "$ALL_REPOS_OK" = false ]; then
        print_error "One or more ECR repositories/tags referenced in task definitions were not found."
        echo -e "$FAILURE_DETAILS" # Show summary of failures
    else
        print_success "All checked ECR repositories and tags were found."
    fi
}

# Check monitoring services (Grafana, Prometheus ECS Services)
check_monitoring() {
    print_header "MONITORING SERVICES (ECS)"

    # Use stored ALB DNS if available
    if [ -z "$CHECK_ALB_DNS" ]; then
        print_warning "ALB DNS not available, skipping endpoint checks."
        ALB_DNS="" # Ensure it's empty
    else
        ALB_DNS="$CHECK_ALB_DNS"
    fi

    # Check Grafana Service (assuming name convention *-grafana-service)
    GRAFANA_SERVICE_ARN=$(aws ecs list-services --cluster "$CLUSTER_ARN" --query "serviceArns[?contains(@, \`$PROJECT_NAME-grafana-service\`)]" --output text --region "$AWS_REGION")
    if [ -z "$GRAFANA_SERVICE_ARN" ]; then
        print_error "Grafana ECS service not found (expected name like '$PROJECT_NAME-grafana-service')."
    else
        SERVICE_DETAIL=$(aws ecs describe-services --cluster "$CLUSTER_ARN" --services "$GRAFANA_SERVICE_ARN" --query "services[0].{serviceName:serviceName,status:status,desiredCount:desiredCount,runningCount:runningCount}" --output json --region "$AWS_REGION")
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
        if [ -n "$ALB_DNS" ]; then
            GRAFANA_PATH=${GRAFANA_PATH:-"/grafana"} # Get from env or default
            GRAFANA_URL="http://${ALB_DNS}${GRAFANA_PATH}/api/health" # Use health API
            print_detail "Testing Grafana endpoint: $GRAFANA_URL"
            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "$GRAFANA_URL")
            if [[ "$HTTP_STATUS" == "200" ]]; then
                print_success "Grafana endpoint check returned HTTP $HTTP_STATUS"
            else
                print_error "Grafana endpoint check returned HTTP $HTTP_STATUS"
            fi
        fi
    fi

    # Check Prometheus Service (assuming name convention *-prometheus-service)
    PROM_SERVICE_ARN=$(aws ecs list-services --cluster "$CLUSTER_ARN" --query "serviceArns[?contains(@, \`$PROJECT_NAME-prometheus-service\`)]" --output text --region "$AWS_REGION")
     if [ -z "$PROM_SERVICE_ARN" ]; then
        print_error "Prometheus ECS service not found (expected name like '$PROJECT_NAME-prometheus-service')."
    else
        SERVICE_DETAIL=$(aws ecs describe-services --cluster "$CLUSTER_ARN" --services "$PROM_SERVICE_ARN" --query "services[0].{serviceName:serviceName,status:status,desiredCount:desiredCount,runningCount:runningCount}" --output json --region "$AWS_REGION")
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
        if [ -n "$ALB_DNS" ]; then
            PROM_PATH=${PROMETHEUS_PATH:-"/metrics"} # Get from env or default
            PROM_URL="http://${ALB_DNS}${PROM_PATH}"
            print_detail "Testing Prometheus endpoint: $PROM_URL"
            # Prometheus often doesn't need auth and returns 200
            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "$PROM_URL")
            if [[ "$HTTP_STATUS" == "200" ]]; then
                print_success "Prometheus endpoint check returned HTTP $HTTP_STATUS"
            else
                # Could be 404 if path incorrect, or 5xx if error
                print_error "Prometheus endpoint check returned HTTP $HTTP_STATUS"
            fi
        fi
    fi
}

# Check Lambda function based on Project tag
check_lambda() {
    print_header "LAMBDA FUNCTION (Project: $PROJECT_NAME)"
    # Use resourcegroupstaggingapi for reliable tag-based discovery
    FUNCTION_ARN=$(aws resourcegroupstaggingapi get-resources --resource-type-filters lambda:function --tag-filters Key=Project,Values="$PROJECT_NAME" --query 'ResourceTagMappingList[0].ResourceARN' --output text --region "$AWS_REGION" 2>/dev/null)

    if [ -z "$FUNCTION_ARN" ]; then
        print_error "Lambda function with tag Project=$PROJECT_NAME not found via tagging API."
        return 1
    fi

    # Extract function name from ARN
    FUNC_NAME=$(echo "$FUNCTION_ARN" | awk -F: '{print $NF}')

    # Describe using the function NAME, not the ARN
    # Corrected query for get-function (added Configuration. prefix back)
    FUNCTION_STATE_INFO=$(aws lambda get-function --function-name "$FUNC_NAME" --query 'Configuration.{State:State,LastUpdateStatus:LastUpdateStatus}' --output json --region "$AWS_REGION" 2>/dev/null)
    FUNCTION_CONFIG_INFO=$(aws lambda get-function-configuration --function-name "$FUNC_NAME" --query '{FunctionName:FunctionName,Runtime:Runtime,MemorySize:MemorySize,Timeout:Timeout,LastModified:LastModified}' --output json --region "$AWS_REGION" 2>/dev/null)

    # Use printf for piping to jq and check the result
    JQ_RESULT=$(printf '%s' "$FUNCTION_CONFIG_INFO" | jq -r '.FunctionName // "null"')

    if [ -z "$FUNCTION_CONFIG_INFO" ] || [ "$JQ_RESULT" == "null" ]; then
         # Use FUNC_NAME in error message as ARN lookup succeeded
         print_error "Failed to describe Lambda function '$FUNC_NAME'."
         return 1
    fi

    # Use printf when piping to jq for safety
    FUNC_RUNTIME=$(printf '%s' "$FUNCTION_CONFIG_INFO" | jq -r '.Runtime')
    FUNC_MEMORY=$(printf '%s' "$FUNCTION_CONFIG_INFO" | jq -r '.MemorySize')
    FUNC_TIMEOUT=$(printf '%s' "$FUNCTION_CONFIG_INFO" | jq -r '.Timeout')
    FUNC_LAST_MODIFIED=$(printf '%s' "$FUNCTION_CONFIG_INFO" | jq -r '.LastModified')
    FUNC_STATE=$(printf '%s' "$FUNCTION_STATE_INFO" | jq -r '.State // "Unknown"')
    FUNC_LAST_UPDATE=$(printf '%s' "$FUNCTION_STATE_INFO" | jq -r '.LastUpdateStatus // "Unknown"')

    if [ "$FUNC_STATE" == "Active" ] && [[ "$FUNC_LAST_UPDATE" == "Successful" || "$FUNC_LAST_UPDATE" == "InProgress" ]]; then
         print_success "Lambda: $FUNC_NAME ($FUNC_RUNTIME)"
         print_detail "State: $FUNC_STATE, Last Update: $FUNC_LAST_UPDATE"
    else
         print_error "Lambda: $FUNC_NAME ($FUNC_RUNTIME) - State: $FUNC_STATE, Last Update: $FUNC_LAST_UPDATE"
    fi

     print_detail "Memory: ${FUNC_MEMORY}MB, Timeout: ${FUNC_TIMEOUT}s, Last Modified: $FUNC_LAST_MODIFIED"
}

# Check for potentially orphaned / unused resources specific to the project
check_orphaned_resources() {
    print_header "POTENTIAL ORPHANED RESOURCES"

    # Check for project-tagged Security Groups not attached to anything
    print_detail "Checking for unused project-tagged Security Groups..."
    PROJECT_SGS=$(aws ec2 describe-security-groups --filters "Name=tag:Project,Values=$PROJECT_NAME" --query "SecurityGroups[*].GroupId" --output text --region "$AWS_REGION")
    UNUSED_SG_FOUND=false
    for sg_id in $PROJECT_SGS; do
        # Check ENIs - primary usage indicator
        ENI_USAGE=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$sg_id" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text --region "$AWS_REGION")
        # Add checks for other services (LB, RDS, Lambda, EC2) if they might use SGs directly without ENIs showing up easily
        if [[ -z "$ENI_USAGE" ]]; then
             SG_NAME=$(aws ec2 describe-security-groups --group-ids "$sg_id" --query "SecurityGroups[0].GroupName" --output text --region "$AWS_REGION")
             print_warning "Security Group $SG_NAME ($sg_id) tagged with project may be unused (no ENIs found)."
             UNUSED_SG_FOUND=true
        fi
    done
    if [ "$UNUSED_SG_FOUND" = false ]; then
        print_success "No project-tagged Security Groups appear obviously unused."
    fi


    # Check for unattached EBS volumes (consider adding Project tag check if volumes are tagged)
    print_detail "Checking for unattached EBS volumes..."
    VOLUMES=$(aws ec2 describe-volumes --filters "Name=status,Values=available" --query "Volumes[*].{ID:VolumeId,Size:Size,Created:CreateTime, ProjectTag:Tags[?Key=='Project']|[0].Value}" --output json --region "$AWS_REGION")
    UNATTACHED_COUNT=$(echo "$VOLUMES" | jq --arg proj "$PROJECT_NAME" '[.[] | select(.ProjectTag == null or .ProjectTag != $proj)] | length')
    PROJECT_UNATTACHED=$(echo "$VOLUMES" | jq --arg proj "$PROJECT_NAME" '[.[] | select(.ProjectTag == $proj) ]')
    PROJECT_UNATTACHED_COUNT=$(echo "$PROJECT_UNATTACHED" | jq '. | length')

    if [ "$PROJECT_UNATTACHED_COUNT" -eq 0 ]; then
        print_success "No unattached EBS volumes tagged with Project=$PROJECT_NAME found."
    else
        print_warning "$PROJECT_UNATTACHED_COUNT unattached EBS volume(s) tagged with Project=$PROJECT_NAME found:"
        echo "$PROJECT_UNATTACHED" | jq -c '.[]' | while read -r volume; do
            VOLUME_ID=$(echo "$volume" | jq -r '.ID')
            SIZE=$(echo "$volume" | jq -r '.Size')
            CREATED=$(echo "$volume" | jq -r '.Created')
            print_detail "  ${S_ARROW} $VOLUME_ID (${SIZE}GB, created $CREATED)"
        done
         ((CHECKS_FAILED++)) # Count this as a failure to investigate
    fi
     if [ "$UNATTACHED_COUNT" -gt 0 ]; then
         print_info "$UNATTACHED_COUNT other unattached EBS volume(s) found (untagged or different project)."
    fi


    # Check for unallocated Elastic IPs (consider adding Project tag check if EIPs are tagged)
    print_detail "Checking for unallocated Elastic IPs..."
    UNUSED_EIPS=$(aws ec2 describe-addresses --query "Addresses[?AssociationId==null].{AllocationId:AllocationId,PublicIp:PublicIp, ProjectTag:Tags[?Key=='Project']|[0].Value}" --output json --region "$AWS_REGION")
    UNALLOCATED_COUNT=$(echo "$UNUSED_EIPS" | jq --arg proj "$PROJECT_NAME" '[.[] | select(.ProjectTag == null or .ProjectTag != $proj)] | length')
    PROJECT_UNALLOCATED=$(echo "$UNUSED_EIPS" | jq --arg proj "$PROJECT_NAME" '[.[] | select(.ProjectTag == $proj) ]')
    PROJECT_UNALLOCATED_COUNT=$(echo "$PROJECT_UNALLOCATED" | jq '. | length')

    if [ "$PROJECT_UNALLOCATED_COUNT" -eq 0 ]; then
        print_success "No unallocated Elastic IPs tagged with Project=$PROJECT_NAME found."
    else
         print_warning "$PROJECT_UNALLOCATED_COUNT unallocated EIP(s) tagged with Project=$PROJECT_NAME found:"
        echo "$PROJECT_UNALLOCATED" | jq -c '.[]' | while read -r eip; do
            EIP_ID=$(echo "$eip" | jq -r '.AllocationId')
            EIP_IP=$(echo "$eip" | jq -r '.PublicIp')
            print_detail "  ${S_ARROW} $EIP_IP ($EIP_ID)"
         done
         ((CHECKS_FAILED++)) # Count this as a failure to investigate
    fi
    if [ "$UNALLOCATED_COUNT" -gt 0 ]; then
         print_info "$UNALLOCATED_COUNT other unallocated EIP(s) found (untagged or different project)."
    fi


    # Check for old ECS task definitions (families prefixed with project name)
    print_detail "Checking for excessive inactive ECS task definition revisions..."
    FAMILIES=$(aws ecs list-task-definition-families --family-prefix "$PROJECT_NAME" --status ACTIVE --query "families" --output text --region "$AWS_REGION")
    HIGH_REVISION_FOUND=false
    if [ -n "$FAMILIES" ]; then
        for family in $FAMILIES; do
            # Get count of *all* revisions (active and inactive)
            TOTAL_REVISIONS=$(aws ecs list-task-definitions --family-prefix "$family" --status ACTIVE --query "length(taskDefinitionArns)" --output text --region "$AWS_REGION") # Check ACTIVE only? Or all? List shows ACTIVE. Describe needed for inactive?
            INACTIVE_REVISIONS=$(aws ecs list-task-definitions --family-prefix "$family" --status INACTIVE --query "length(taskDefinitionArns)" --output text --region "$AWS_REGION")
            ALL_REVS=$((TOTAL_REVISIONS + INACTIVE_REVISIONS))

            # Define threshold (e.g., more than 10 total revisions)
            THRESHOLD=10
            if [ "$ALL_REVS" -gt "$THRESHOLD" ]; then
                print_warning "Task definition family '$family' has $ALL_REVS total revisions (>$THRESHOLD), consider cleanup."
                HIGH_REVISION_FOUND=true
            fi
        done
    fi
     if [ "$HIGH_REVISION_FOUND" = false ]; then
        print_success "No task definition families found with excessive revisions (> $THRESHOLD)."
    fi
}


# --- Main Execution ---

# Run AWS config check first
check_aws_config

# Get Cluster ARN once for efficiency
# Ensure this happens *before* check_ecs and check_monitoring are called
CLUSTER_ARN=""
ALL_CLUSTERS=$(aws ecs list-clusters --query clusterArns --output json --region "$AWS_REGION")
for arn in $(echo "$ALL_CLUSTERS" | jq -r '.[]'); do
  TAGS=$(aws ecs describe-clusters --clusters "$arn" --include TAGS --query "clusters[0].tags" --output json --region "$AWS_REGION" 2>/dev/null)
  PROJECT_TAG_VAL=$(echo "$TAGS" | jq -r --arg proj "$PROJECT_NAME" '.[] | select(.key=="Project" and .value==$proj) | .value')
  if [ "$PROJECT_TAG_VAL" == "$PROJECT_NAME" ]; then
    CLUSTER_ARN="$arn"
    break
  fi
done
# Export cluster ARN for use in checks
export CHECK_CLUSTER_ARN="$CLUSTER_ARN"

# Run checks for core components
check_vpc
check_rds
check_ecs # Uses exported CHECK_CLUSTER_ARN
check_alb # Exports CHECK_ALB_DNS on success
check_ecr
check_lambda
check_monitoring # Uses exported CHECK_CLUSTER_ARN and CHECK_ALB_DNS

# Run checks for potential issues
check_orphaned_resources

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
