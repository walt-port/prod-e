#!/bin/bash

# Resource Check Script for Production Experience Showcase
# This script checks the status of all AWS resources deployed in the project

# Set AWS region
AWS_REGION="us-west-2"

# ANSI color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# CSV output option
CSV_OUTPUT=false
CSV_FILE="resource_check_results.csv"

# Print header with section name
print_header() {
  echo -e "\n${BLUE}======== $1 ========${NC}\n"
  if [ "$CSV_OUTPUT" = true ]; then
    echo "Section,$1" >> $CSV_FILE
  fi
}

# Print success message
print_success() {
  echo -e "${GREEN}✓ $1${NC}"
  if [ "$CSV_OUTPUT" = true ]; then
    echo "Success,$1" >> $CSV_FILE
  fi
}

# Print error message
print_error() {
  echo -e "${RED}✗ $1${NC}"
  if [ "$CSV_OUTPUT" = true ]; then
    echo "Error,$1" >> $CSV_FILE
  fi
}

# Print warning/info message
print_info() {
  echo -e "${YELLOW}ℹ $1${NC}"
  if [ "$CSV_OUTPUT" = true ]; then
    echo "Info,$1" >> $CSV_FILE
  fi
}

# Print detail message (indented gray text)
print_detail() {
  echo -e "${GRAY}  → $1${NC}"
  if [ "$CSV_OUTPUT" = true ]; then
    echo "Detail,$1" >> $CSV_FILE
  fi
}

# Process command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --region=*) AWS_REGION="${1#*=}" ;;
    --csv) CSV_OUTPUT=true ;;
    --output=*) CSV_FILE="${1#*=}" ;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --region=REGION Set AWS region (default: us-west-2)"
      echo "  --csv           Output results to CSV file (default: resource_check_results.csv)"
      echo "  --output=FILENAME Output results to specified CSV file"
      echo "  --help, -h      Display this help message"
      exit 0
      ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Initialize CSV file if needed
if [ "$CSV_OUTPUT" = true ]; then
  echo "Type,Resource,Details" > $CSV_FILE
  echo "CSV output will be written to $CSV_FILE"
fi

# Print script header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    PRODUCTION EXPERIENCE RESOURCE CHECK     ${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Starting check at $(date)"
echo -e "${GRAY}Region: $AWS_REGION${NC}\n"

# Check AWS CLI configuration
check_aws_config() {
  print_header "CHECKING AWS CONFIGURATION"

  if aws sts get-caller-identity > /dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
    USER_ARN=$(aws sts get-caller-identity --query "Arn" --output text)
    print_success "AWS CLI is configured correctly"
    print_info "Account ID: $ACCOUNT_ID"
    print_info "User: $USER_ARN"
    print_info "Region: $AWS_REGION"
  else
    print_error "AWS CLI is not configured correctly"
    exit 1
  fi
}

# Check VPC and networking resources
check_vpc() {
  print_header "CHECKING VPC RESOURCES"

  # Get VPC
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=prod-e-vpc" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)

  if [[ "$VPC_ID" == "None" || -z "$VPC_ID" ]]; then
    print_error "VPC not found with tag Project=prod-e"
  else
    print_success "VPC found: $VPC_ID"

    # Check subnets
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].[SubnetId,CidrBlock,AvailabilityZone]" --output text --region $AWS_REGION)

    if [[ -z "$SUBNETS" ]]; then
      print_error "No subnets found in VPC $VPC_ID"
    else
      SUBNET_COUNT=$(echo "$SUBNETS" | wc -l)
      print_success "Found $SUBNET_COUNT subnets in VPC $VPC_ID"

      echo "$SUBNETS" | while read -r SUBNET_ID CIDR AZ; do
        print_detail "Subnet: $SUBNET_ID, CIDR: $CIDR, AZ: $AZ"
      done
    fi

    # Check Internet Gateway
    IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text --region $AWS_REGION)

    if [[ "$IGW" == "None" || -z "$IGW" ]]; then
      print_error "No Internet Gateway attached to VPC $VPC_ID"
    else
      print_success "Internet Gateway found: $IGW"
    fi

    # Check NAT Gateways
    NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[*].[NatGatewayId,State]" --output text --region $AWS_REGION)

    if [[ -z "$NAT_GATEWAYS" ]]; then
      print_error "No NAT Gateways found in VPC $VPC_ID"
    else
      NAT_COUNT=$(echo "$NAT_GATEWAYS" | wc -l)
      print_success "Found $NAT_COUNT NAT Gateway(s) in VPC $VPC_ID"

      echo "$NAT_GATEWAYS" | while read -r NAT_ID STATE; do
        print_detail "NAT Gateway: $NAT_ID, State: $STATE"
      done
    fi

    # Check Route Tables
    ROUTE_TABLES=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[*].[RouteTableId]" --output text --region $AWS_REGION)

    if [[ -z "$ROUTE_TABLES" ]]; then
      print_error "No route tables found in VPC $VPC_ID"
    else
      RT_COUNT=$(echo "$ROUTE_TABLES" | wc -l)
      print_success "Found $RT_COUNT route table(s) in VPC $VPC_ID"

      echo "$ROUTE_TABLES" | while read -r RT_ID; do
        ROUTES=$(aws ec2 describe-route-tables --route-table-id $RT_ID --query "RouteTables[0].Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId]" --output text --region $AWS_REGION)
        print_detail "Route Table: $RT_ID"
        echo "$ROUTES" | while read -r DEST GW NAT; do
          if [[ -n "$GW" && "$GW" != "None" ]]; then
            print_detail "  → Route: $DEST via $GW"
          elif [[ -n "$NAT" && "$NAT" != "None" ]]; then
            print_detail "  → Route: $DEST via NAT $NAT"
          fi
        done
      done
    fi

    # Check Security Groups
    SEC_GROUPS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[*].[GroupId,GroupName]" --output text --region $AWS_REGION)

    if [[ -z "$SEC_GROUPS" ]]; then
      print_error "No security groups found in VPC $VPC_ID"
    else
      SG_COUNT=$(echo "$SEC_GROUPS" | wc -l)
      print_success "Found $SG_COUNT security group(s) in VPC $VPC_ID"

      echo "$SEC_GROUPS" | while read -r SG_ID SG_NAME; do
        print_detail "Security Group: $SG_ID, Name: $SG_NAME"
      done
    fi
  fi

  # Check for unused Elastic IPs
  print_info "Checking for unused Elastic IPs..."
  UNUSED_EIPS=$(aws ec2 describe-addresses --query "Addresses[?AssociationId==null].[AllocationId,PublicIp]" --output text --region $AWS_REGION)

  if [[ -z "$UNUSED_EIPS" ]]; then
    print_success "No unused Elastic IPs found"
  else
    echo "$UNUSED_EIPS" | while read -r line; do
      EIP_ID=$(echo $line | awk '{print $1}')
      EIP_IP=$(echo $line | awk '{print $2}')
      print_detail "Unused Elastic IP: $EIP_IP ($EIP_ID)"
    done
  fi
}

# Check RDS resources
check_rds() {
  print_header "CHECKING RDS RESOURCES"

  # Get DB instances
  DB_INSTANCES=$(aws rds describe-db-instances --output text --region $AWS_REGION --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address,Endpoint.Port]")

  if [[ -z "$DB_INSTANCES" ]]; then
    print_error "No DB instances found"
  else
    echo "$DB_INSTANCES" | while read -r id status endpoint port; do
      if [[ "$status" == "available" ]]; then
        print_success "$id: $status at $endpoint:$port"
      else
        print_info "$id: $status at $endpoint:$port"
      fi
    done
  fi

  # Check DB subnet groups
  SUBNET_GROUPS=$(aws rds describe-db-subnet-groups --output text --region $AWS_REGION --query "DBSubnetGroups[*].[DBSubnetGroupName,SubnetGroupStatus]")

  if [[ -z "$SUBNET_GROUPS" ]]; then
    print_error "No DB subnet groups found"
  else
    echo "$SUBNET_GROUPS" | while read -r name status; do
      print_success "$name: $status"
    done
  fi

  # Check for DB snapshots
  print_info "Checking for RDS snapshots..."
  SNAPSHOTS=$(aws rds describe-db-snapshots --snapshot-type manual --query "DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,Status,DBInstanceIdentifier]" --output text --region $AWS_REGION)

  if [[ -z "$SNAPSHOTS" ]]; then
    print_success "No manual DB snapshots found"
  else
    echo "$SNAPSHOTS" | while read -r id time status instance; do
      print_info "Snapshot: $id from $instance created at $time ($status)"
    done
  fi
}

# Check ECS resources
check_ecs() {
  print_header "CHECKING ECS RESOURCES"

  # Check ECS cluster
  CLUSTER_DATA=$(aws ecs describe-clusters --clusters prod-e-cluster --output text --region $AWS_REGION --query "clusters[*].[clusterName,status,activeServicesCount]")

  if [[ -z "$CLUSTER_DATA" ]]; then
    print_error "ECS cluster not found"
  else
    echo "$CLUSTER_DATA" | while read -r name status services; do
      print_success "$name: $status with $services active services"
    done

    # Check ECS services
    SERVICES=$(aws ecs list-services --cluster prod-e-cluster --output text --region $AWS_REGION --query "serviceArns")

    if [[ -z "$SERVICES" ]]; then
      print_error "No ECS services found"
    else
      for service in $SERVICES; do
        SERVICE_DATA=$(aws ecs describe-services --cluster prod-e-cluster --services $service --output text --region $AWS_REGION --query "services[*].[serviceName,status,desiredCount,runningCount]")
        echo "$SERVICE_DATA" | while read -r name status desired running; do
          if [[ "$status" == "ACTIVE" && "$desired" == "$running" ]]; then
            print_success "$name: $status ($running/$desired tasks running)"
          else
            print_info "$name: $status ($running/$desired tasks running)"
          fi
        done
      done
    fi

    # Check running tasks
    TASKS=$(aws ecs list-tasks --cluster prod-e-cluster --output text --region $AWS_REGION --query "taskArns")

    if [[ -z "$TASKS" ]]; then
      print_error "No ECS tasks running"
    else
      TASK_COUNT=$(echo "$TASKS" | wc -w)
      print_success "$TASK_COUNT tasks running"

      for task in $TASKS; do
        TASK_DATA=$(aws ecs describe-tasks --cluster prod-e-cluster --tasks $task --output text --region $AWS_REGION --query "tasks[*].[taskArn,lastStatus,healthStatus]")
        echo "$TASK_DATA" | while read -r arn status health; do
          TASK_ID=$(echo "$arn" | awk -F/ '{print $NF}')
          if [[ "$status" == "RUNNING" && "$health" == "HEALTHY" ]]; then
            print_success "  $TASK_ID: $status ($health)"
          else
            print_info "  $TASK_ID: $status ($health)"
          fi
        done
      done
    fi

    # Check task definitions
    print_info "Checking for task definitions..."

    # Check all task definition families
    FAMILIES=$(aws ecs list-task-definition-families --status ACTIVE --query "families" --output text --region $AWS_REGION)

    for family in $FAMILIES; do
      # Count total revisions for this family
      TOTAL_REVISIONS=$(aws ecs list-task-definitions --family-prefix $family --status ACTIVE --query "length(taskDefinitionArns)" --output text --region $AWS_REGION)

      # Get the active revision
      ACTIVE_REVISION=""
      for service in $SERVICES; do
        SERVICE_NAME=$(echo $service | awk -F/ '{print $NF}')
        SERVICE_TASK_DEF=$(aws ecs describe-services --cluster prod-e-cluster --services $SERVICE_NAME --query "services[0].taskDefinition" --output text --region $AWS_REGION)

        if [[ "$SERVICE_TASK_DEF" == *"$family"* ]]; then
          ACTIVE_REVISION=$(echo $SERVICE_TASK_DEF | awk -F: '{print $NF}')
          break
        fi
      done

      if [[ -n "$ACTIVE_REVISION" ]]; then
        print_success "Family: $family has $TOTAL_REVISIONS revisions (active: $ACTIVE_REVISION)"
      else
        print_detail "Family: $family has $TOTAL_REVISIONS revisions (no active service)"
      fi
    done
  fi
}

# Check ALB resources
check_alb() {
  print_header "CHECKING LOAD BALANCER RESOURCES"

  # Check ALBs
  ALBS=$(aws elbv2 describe-load-balancers --output text --region $AWS_REGION --query "LoadBalancers[*].[LoadBalancerName,DNSName,State.Code,Type]")

  if [[ -z "$ALBS" ]]; then
    print_error "No Application Load Balancers found"
  else
    echo "$ALBS" | while read -r name dns state type; do
      if [[ "$state" == "active" ]]; then
        print_success "$name: $state ($type) | $dns"
      else
        print_info "$name: $state ($type) | $dns"
      fi
    done

    # Get ALB ARN for target groups - using the correct load balancer name 'prod-e-alb'
    ALB_ARN=$(aws elbv2 describe-load-balancers --names prod-e-alb --query "LoadBalancers[0].LoadBalancerArn" --output text --region $AWS_REGION)

    # Check target groups
    TARGET_GROUPS=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --output text --region $AWS_REGION --query "TargetGroups[*].[TargetGroupName,Port,Protocol,TargetType]")

    if [[ -z "$TARGET_GROUPS" ]]; then
      print_error "No target groups found"
    else
      echo "$TARGET_GROUPS" | while read -r name port protocol target_type; do
        print_success "  $name: $protocol:$port ($target_type)"
      done
    fi

    # Check for each target group's health
    echo "Checking target group health status:"
    TARGET_GROUP_ARNS=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --query "TargetGroups[*].TargetGroupArn" --output text --region $AWS_REGION)

    for tg_arn in $TARGET_GROUP_ARNS; do
      TG_NAME=$(aws elbv2 describe-target-groups --target-group-arns $tg_arn --query "TargetGroups[0].TargetGroupName" --output text --region $AWS_REGION)

      # Get health status
      TARGETS_HEALTH=$(aws elbv2 describe-target-health --target-group-arn $tg_arn --query "TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State]" --output text --region $AWS_REGION)

      if [[ -z "$TARGETS_HEALTH" ]]; then
        print_info "  $TG_NAME: No targets registered"
      else
        echo "$TARGETS_HEALTH" | while read -r id port state; do
          if [[ "$state" == "healthy" ]]; then
            print_success "  $TG_NAME: Target $id:$port is $state"
          elif [[ "$state" == "draining" ]]; then
            print_detail "  $TG_NAME: Target $id:$port is $state"
          else
            print_error "  $TG_NAME: Target $id:$port is $state"
          fi
        done
      fi
    done
  fi
}

# Check ECR repositories
check_ecr() {
  print_header "CHECKING ECR REPOSITORIES"

  # List ECR repositories
  REPOS=$(aws ecr describe-repositories --output text --region $AWS_REGION --query "repositories[*].[repositoryName,repositoryUri]")

  if [[ -z "$REPOS" ]]; then
    print_error "No ECR repositories found"
  else
    echo "$REPOS" | while read -r name uri; do
      print_success "$name: $uri"

      # List the latest image
      LATEST_IMAGE=$(aws ecr describe-images --repository-name "$name" --output text --region $AWS_REGION --query "sort_by(imageDetails,& imagePushedAt)[-1].[imageTags[0],imagePushedAt]" 2>/dev/null || echo "None")

      if [[ "$LATEST_IMAGE" == "None" || -z "$LATEST_IMAGE" ]]; then
        print_info "  No images found"
      else
        TAG=$(echo "$LATEST_IMAGE" | awk '{print $1}')
        PUSHED_AT=$(echo "$LATEST_IMAGE" | awk '{print $2}')
        print_info "  Latest image: ${TAG:-untagged} pushed at $PUSHED_AT"

        # Count total images in the repository
        IMAGE_COUNT=$(aws ecr describe-images --repository-name "$name" --query "length(imageDetails)" --output text --region $AWS_REGION 2>/dev/null || echo "0")

        if [ "$IMAGE_COUNT" -gt 1 ]; then
          print_info "  Total images: $IMAGE_COUNT"
        fi
      fi
    done
  fi
}

# Check S3 and DynamoDB for Terraform state
check_terraform_state() {
  print_header "CHECKING TERRAFORM STATE RESOURCES"

  # Check S3 bucket
  S3_BUCKET="prod-e-terraform-state"
  BUCKET_EXISTS=$(aws s3api head-bucket --bucket "$S3_BUCKET" 2>&1 || echo "error")

  if [[ "$BUCKET_EXISTS" == "error" ]]; then
    print_error "Terraform state S3 bucket not found: $S3_BUCKET"
  else
    print_success "Terraform state S3 bucket exists: $S3_BUCKET"

    # Check if state file exists
    STATE_FILE=$(aws s3 ls "s3://$S3_BUCKET/terraform.tfstate" 2>&1 || echo "error")

    if [[ "$STATE_FILE" == "error" || -z "$STATE_FILE" ]]; then
      print_error "Terraform state file not found in S3 bucket"
    else
      print_success "Terraform state file exists"
      print_detail "  $STATE_FILE"
    fi
  fi

  # Check DynamoDB table
  DYNAMO_TABLE="prod-e-terraform-lock"
  TABLE_EXISTS=$(aws dynamodb describe-table --table-name "$DYNAMO_TABLE" --query "Table.TableName" --output text --region $AWS_REGION 2>&1 || echo "error")

  if [[ "$TABLE_EXISTS" == "error" ]]; then
    print_error "Terraform lock DynamoDB table not found: $DYNAMO_TABLE"
  else
    print_success "Terraform lock DynamoDB table exists: $DYNAMO_TABLE"

    # Check table status
    TABLE_STATUS=$(aws dynamodb describe-table --table-name "$DYNAMO_TABLE" --query "Table.TableStatus" --output text --region $AWS_REGION)
    print_detail "  Table status: $TABLE_STATUS"
  fi
}

# Check monitoring services
check_monitoring() {
  print_header "CHECKING MONITORING SERVICES"

  # Check Prometheus
  PROM_SERVICE=$(aws ecs describe-services --cluster prod-e-cluster --services prometheus-service --region $AWS_REGION --query "services[0].[serviceName,desiredCount,runningCount]" --output text 2>/dev/null)

  if [[ -z "$PROM_SERVICE" ]]; then
    print_error "Prometheus service not found"
  else
    read -r name desired running <<< "$PROM_SERVICE"
    if [[ "$desired" == "$running" ]]; then
      print_success "Prometheus: ACTIVE ($running/$desired tasks running)"
    else
      print_error "Prometheus: DEGRADED ($running/$desired tasks running)"
    fi
  fi

  # Check Grafana
  GRAFANA_SERVICE=$(aws ecs describe-services --cluster prod-e-cluster --services grafana-service --region $AWS_REGION --query "services[0].[serviceName,desiredCount,runningCount]" --output text 2>/dev/null)

  if [[ -z "$GRAFANA_SERVICE" ]]; then
    print_error "Grafana service not found"
  else
    read -r name desired running <<< "$GRAFANA_SERVICE"
    if [[ "$desired" == "$running" ]]; then
      print_success "Grafana: ACTIVE ($running/$desired tasks running)"
    else
      print_error "Grafana: DEGRADED ($running/$desired tasks running)"
    fi
  fi

  # Get ALB DNS for endpoint checks
  ALB_DNS=$(aws elbv2 describe-load-balancers --names prod-e-alb --query "LoadBalancers[0].DNSName" --output text --region $AWS_REGION)

  if [[ -n "$ALB_DNS" ]]; then
    # Check Grafana endpoint health
    GRAFANA_URL="http://$ALB_DNS/grafana/"
    print_detail "Testing Grafana endpoint: $GRAFANA_URL"

    GRAFANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -m 5 $GRAFANA_URL 2>/dev/null)

    if [[ "$GRAFANA_STATUS" == "200" || "$GRAFANA_STATUS" == "302" ]]; then
      print_success "Grafana endpoint is accessible (HTTP $GRAFANA_STATUS)"
    else
      print_error "Grafana endpoint returned HTTP $GRAFANA_STATUS"
    fi

    # Try to access Prometheus metrics endpoint via Grafana
    PROM_URL="http://$ALB_DNS/grafana/api/datasources/proxy/1/api/v1/query?query=up"
    print_detail "Testing Prometheus metrics via Grafana proxy"

    PROM_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -m 5 $PROM_URL 2>/dev/null)

    if [[ "$PROM_STATUS" == "200" || "$PROM_STATUS" == "401" ]]; then
      print_success "Prometheus metrics endpoint is accessible (HTTP $PROM_STATUS)"
    else
      print_error "Prometheus metrics endpoint returned HTTP $PROM_STATUS"
    fi
  else
    print_error "Could not determine ALB DNS name for endpoint checks"
  fi
}

# Check EFS Resources
check_efs() {
  print_header "CHECKING EFS RESOURCES"

  # Get EFS file systems
  FS_IDS=$(aws efs describe-file-systems --query "FileSystems[?Tags[?Key=='Project' && Value=='prod-e']].FileSystemId" --output text --region $AWS_REGION)

  if [[ -z "$FS_IDS" ]]; then
    print_error "No EFS file systems found for the project"
  else
    for fs_id in $FS_IDS; do
      # Get file system details
      FS_INFO=$(aws efs describe-file-systems --file-system-id $fs_id --query "FileSystems[0].[FileSystemId,LifeCycleState,SizeInBytes.Value]" --output text --region $AWS_REGION)
      FS_ID=$(echo $FS_INFO | awk '{print $1}')
      STATE=$(echo $FS_INFO | awk '{print $2}')
      SIZE_BYTES=$(echo $FS_INFO | awk '{print $3}')

      # Convert bytes to MB using bash arithmetic instead of bc
      SIZE_MB=$((SIZE_BYTES / 1024 / 1024))

      if [[ "$STATE" == "available" ]]; then
        print_success "EFS file system: $FS_ID is $STATE ($SIZE_MB MB used)"
      else
        print_error "EFS file system: $FS_ID is $STATE"
      fi

      # Check mount targets
      MOUNT_TARGETS=$(aws efs describe-mount-targets --file-system-id $fs_id --query "MountTargets[*].[MountTargetId,SubnetId,LifeCycleState]" --output text --region $AWS_REGION)

      if [[ -z "$MOUNT_TARGETS" ]]; then
        print_error "  No mount targets found for $FS_ID"
      else
        echo "$MOUNT_TARGETS" | while read -r mt_id subnet_id mt_state; do
          if [[ "$mt_state" == "available" ]]; then
            print_success "  Mount target: $mt_id is $mt_state in subnet $subnet_id"
          else
            print_error "  Mount target: $mt_id is $mt_state in subnet $subnet_id"
          fi
        done
      fi

      # Check access points
      ACCESS_POINTS=$(aws efs describe-access-points --file-system-id $fs_id --query "AccessPoints[*].[AccessPointId,LifeCycleState]" --output text --region $AWS_REGION)

      if [[ -z "$ACCESS_POINTS" ]]; then
        print_detail "  No access points found for $FS_ID"
      else
        echo "$ACCESS_POINTS" | while read -r ap_id ap_state; do
          if [[ "$ap_state" == "available" ]]; then
            print_success "  Access point: $ap_id is $ap_state"
          else
            print_error "  Access point: $ap_id is $ap_state"
          fi
        done
      fi
    done
  fi
}

# Check Lambda functions
check_lambda() {
  print_header "CHECKING LAMBDA FUNCTIONS"

  # List Lambda functions
  FUNCTIONS=$(aws lambda list-functions --region $AWS_REGION --query "Functions[?contains(FunctionName, 'prod-e') || contains(FunctionName, 'grafana')].[FunctionName,Runtime,LastModified,State]" --output text)

  if [[ -z "$FUNCTIONS" ]]; then
    print_error "No Lambda functions found for the project"
  else
    echo "$FUNCTIONS" | while read -r name runtime modified state; do
      if [[ "$state" == "Active" ]]; then
        print_success "Function: $name ($runtime) last modified $modified is $state"
      else
        print_info "Function: $name ($runtime) last modified $modified is $state"
      fi

      # Check function configuration (memory, timeout)
      CONFIG=$(aws lambda get-function-configuration --function-name "$name" --region $AWS_REGION --query "[MemorySize,Timeout]" --output text)
      MEMORY=$(echo "$CONFIG" | awk '{print $1}')
      TIMEOUT=$(echo "$CONFIG" | awk '{print $2}')
      print_detail "Memory: ${MEMORY}MB, Timeout: ${TIMEOUT}s"

      # Get recent invocations
      INVOCATIONS=$(aws lambda get-function --function-name "$name" --region $AWS_REGION --query "Configuration.LastUpdateStatus" --output text)
      print_detail "Last update status: $INVOCATIONS"

      # Check function versions
      VERSIONS=$(aws lambda list-versions-by-function --function-name "$name" --region $AWS_REGION --query "length(Versions)" --output text)
      print_detail "Function versions: $VERSIONS"
    done
  fi

  # Check Lambda event source mappings
  print_detail "Checking Lambda event source mappings..."
  EVENT_MAPPINGS=$(aws lambda list-event-source-mappings --region $AWS_REGION --query "EventSourceMappings[?contains(FunctionArn, 'prod-e') || contains(FunctionArn, 'grafana')].[UUID,EventSourceArn,State]" --output text)

  if [[ -z "$EVENT_MAPPINGS" ]]; then
    print_detail "No event source mappings found"
  else
    echo "$EVENT_MAPPINGS" | while read -r uuid source state; do
      if [[ "$state" == "Enabled" ]]; then
        print_success "Event mapping: $uuid is $state (source: $source)"
      else
        print_detail "Event mapping: $uuid is $state (source: $source)"
      fi
    done
  fi
}

# Check for unused security groups
check_security_groups() {
  print_header "CHECKING SECURITY GROUPS"

  # Get all security groups
  SECURITY_GROUPS=$(aws ec2 describe-security-groups --region $AWS_REGION --query "SecurityGroups[*].[GroupId,GroupName,Description]" --output text)

  echo "Found $(echo "$SECURITY_GROUPS" | wc -l) security groups:"

  echo "$SECURITY_GROUPS" | while read -r id name desc; do
    # Skip default security groups
    if [[ "$name" == "default" ]]; then
      print_detail "$id: $name - $desc (default)"
      continue
    fi

    # Check if the security group is in use
    IN_USE=false

    # Check EC2 instances
    EC2_USAGE=$(aws ec2 describe-instances --filters "Name=instance.group-id,Values=$id" --query "Reservations[*].Instances[*].InstanceId" --output text --region $AWS_REGION)

    # Check ENIs
    ENI_USAGE=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$id" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text --region $AWS_REGION)

    # Check Load Balancers
    LB_USAGE=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?SecurityGroups[?contains(@, '$id')]].LoadBalancerArn" --output text --region $AWS_REGION)

    # Check RDS instances
    RDS_USAGE=$(aws rds describe-db-instances --query "DBInstances[?VpcSecurityGroups[?VpcSecurityGroupId=='$id']].DBInstanceIdentifier" --output text --region $AWS_REGION)

    # Check Lambda functions
    LAMBDA_USAGE=$(aws lambda list-functions --query "Functions[?VpcConfig.SecurityGroupIds[?contains(@, '$id')]].FunctionName" --output text --region $AWS_REGION)

    # If any of these are non-empty, the security group is in use
    if [[ -n "$EC2_USAGE" || -n "$ENI_USAGE" || -n "$LB_USAGE" || -n "$RDS_USAGE" || -n "$LAMBDA_USAGE" ]]; then
      IN_USE=true
    fi

    if [ "$IN_USE" = true ]; then
      print_success "$id: $name - $desc (in use)"
    else
      print_detail "$id: $name - $desc (not in use)"
    fi
  done
}

# Check for orphaned resources
check_orphaned_resources() {
  print_header "CHECKING FOR ORPHANED RESOURCES"

  # Check for unattached EBS volumes
  print_detail "Checking for unattached EBS volumes..."
  VOLUMES=$(aws ec2 describe-volumes --filters "Name=status,Values=available" --query "Volumes[*].{ID:VolumeId,Size:Size,Created:CreateTime}" --output json --region $AWS_REGION)

  if [ "$(echo $VOLUMES | jq '. | length')" == "0" ]; then
    print_success "No unattached EBS volumes found"
  else
    echo $VOLUMES | jq -c '.[]' | while read -r volume; do
      VOLUME_ID=$(echo $volume | jq -r '.ID')
      SIZE=$(echo $volume | jq -r '.Size')
      CREATED=$(echo $volume | jq -r '.Created')
      print_detail "Unattached EBS volume: $VOLUME_ID (${SIZE}GB, created $CREATED)"
    done
  fi

  # Check for unused Elastic IPs
  print_detail "Checking for unallocated Elastic IPs..."
  UNUSED_EIPS=$(aws ec2 describe-addresses --query "Addresses[?AssociationId==null].[AllocationId,PublicIp]" --output text --region $AWS_REGION)

  if [[ -z "$UNUSED_EIPS" ]]; then
    print_success "No unallocated Elastic IPs found"
  else
    echo "$UNUSED_EIPS" | while read -r line; do
      EIP_ID=$(echo $line | awk '{print $1}')
      EIP_IP=$(echo $line | awk '{print $2}')
      print_detail "Unallocated Elastic IP: $EIP_IP ($EIP_ID)"
    done
  fi

  # Check for old ECS task definitions
  print_detail "Checking for inactive ECS task definitions..."
  FAMILIES=$(aws ecs list-task-definition-families --status ACTIVE --query "families" --output text --region $AWS_REGION)

  for family in $FAMILIES; do
    # Get all revisions for this family
    TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $family --status ACTIVE --query "taskDefinitionArns" --output json --region $AWS_REGION)

    # Count total revisions
    TOTAL_REVISIONS=$(echo $TASK_DEFS | jq '. | length')

    if [ "$TOTAL_REVISIONS" -gt 5 ]; then
      print_detail "Task definition family '$family' has $TOTAL_REVISIONS revisions (consider cleanup)"
    fi
  done
}

# Run all checks
run_all_checks() {
  echo -e "\n${BLUE}===============================================${NC}"
  echo -e "${BLUE}     PRODUCTION EXPERIENCE RESOURCE CHECK     ${NC}"
  echo -e "${BLUE}===============================================${NC}\n"

  check_aws_config
  check_vpc
  check_rds
  check_ecs
  check_alb
  check_ecr
  check_terraform_state
  check_monitoring
  check_efs
  check_lambda
  check_security_groups
  check_orphaned_resources

  echo -e "\n${BLUE}===============================================${NC}"
  echo -e "${BLUE}                 CHECK COMPLETE               ${NC}"
  echo -e "${BLUE}===============================================${NC}\n"
}

# Run all checks by default
run_all_checks

# Exit cleanly
exit 0
