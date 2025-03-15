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
NC='\033[0m' # No Color

# Print header with section name
print_header() {
  echo -e "\n${BLUE}======== $1 ========${NC}\n"
}

# Print success message
print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Print error message
print_error() {
  echo -e "${RED}✗ $1${NC}"
}

# Print warning/info message
print_info() {
  echo -e "${YELLOW}ℹ $1${NC}"
}

# Check AWS CLI configuration
check_aws_config() {
  print_header "CHECKING AWS CONFIGURATION"

  if aws sts get-caller-identity > /dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
    USER_ARN=$(aws sts get-caller-identity --query "Arn" --output text)
    print_success "AWS CLI is configured correctly"
    print_info "Account ID: $ACCOUNT_ID"
    print_info "User: $USER_ARN"
  else
    print_error "AWS CLI is not configured correctly"
    exit 1
  fi
}

# Check VPC and networking resources
check_vpc() {
  print_header "CHECKING VPC RESOURCES"

  # Get VPC
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=prod-e" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)

  if [[ "$VPC_ID" == "None" || -z "$VPC_ID" ]]; then
    print_error "VPC not found"
  else
    print_success "VPC found: $VPC_ID"

    # Check Internet Gateway
    IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text --region $AWS_REGION)
    if [[ "$IGW" == "None" || -z "$IGW" ]]; then
      print_error "Internet Gateway not found"
    else
      print_success "Internet Gateway found: $IGW"
    fi

    # Check Subnets
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].[SubnetId,Tags[?Key=='Name'].Value|[0],AvailabilityZone]" --output text --region $AWS_REGION)
    echo -e "Subnets:"
    echo "$SUBNETS" | while read -r line; do
      SUBNET_ID=$(echo $line | awk '{print $1}')
      SUBNET_NAME=$(echo $line | awk '{print $2}')
      AZ=$(echo $line | awk '{print $3}')
      print_success "  $SUBNET_NAME ($SUBNET_ID) in $AZ"
    done

    # Check NAT Gateway
    NAT=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[?State=='available'].NatGatewayId" --output text --region $AWS_REGION)
    if [[ "$NAT" == "None" || -z "$NAT" ]]; then
      print_error "NAT Gateway not found or not available"
    else
      print_success "NAT Gateway found: $NAT"
    fi
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

    # Get ALB ARN for target groups
    ALB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'application')].LoadBalancerArn" --output text --region $AWS_REGION)

    # Check target groups
    TARGET_GROUPS=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --output text --region $AWS_REGION --query "TargetGroups[*].[TargetGroupName,Port,Protocol,TargetType]")

    if [[ -z "$TARGET_GROUPS" ]]; then
      print_error "No target groups found"
    else
      echo "$TARGET_GROUPS" | while read -r name port protocol target_type; do
        print_success "  $name: $protocol:$port ($target_type)"
      done
    fi
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
      print_info "  $STATE_FILE"
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
    print_info "  Table status: $TABLE_STATUS"
  fi
}

# Check Prometheus and Grafana monitoring services
check_monitoring() {
  print_header "CHECKING MONITORING SERVICES"

  # Check Prometheus ECS service
  PROM_SERVICE=$(aws ecs describe-services --cluster prod-e-cluster --services prod-e-prom-service --output text --region $AWS_REGION --query "services[*].[serviceName,status,desiredCount,runningCount]")

  if [[ -z "$PROM_SERVICE" ]]; then
    print_error "Prometheus service not found"
  else
    echo "$PROM_SERVICE" | while read -r name status desired running; do
      if [[ "$status" == "ACTIVE" && "$desired" == "$running" ]]; then
        print_success "Prometheus: $status ($running/$desired tasks running)"
      else
        print_info "Prometheus: $status ($running/$desired tasks running)"
      fi
    done
  fi

  # Check Grafana ECS service
  GRAFANA_SERVICE=$(aws ecs describe-services --cluster prod-e-cluster --services prod-e-grafana-service --output text --region $AWS_REGION --query "services[*].[serviceName,status,desiredCount,runningCount]" 2>/dev/null || echo "")

  if [[ -z "$GRAFANA_SERVICE" ]]; then
    print_error "Grafana service not found"
  else
    echo "$GRAFANA_SERVICE" | while read -r name status desired running; do
      if [[ "$status" == "ACTIVE" && "$desired" == "$running" ]]; then
        print_success "Grafana: $status ($running/$desired tasks running)"
      else
        print_info "Grafana: $status ($running/$desired tasks running)"
      fi
    done
  fi
}

# Check EFS Resources
check_efs() {
  print_header "CHECKING EFS RESOURCES"

  # List EFS file systems
  EFS_SYSTEMS=$(aws efs describe-file-systems --region $AWS_REGION --query "FileSystems[?contains(Tags[?Key=='Project'].Value, 'prod-e')].[FileSystemId,LifeCycleState,SizeInBytes.Value]" --output text)

  if [[ -z "$EFS_SYSTEMS" ]]; then
    print_error "No EFS file systems found for the project"
  else
    echo "$EFS_SYSTEMS" | while read -r id state size; do
      if [[ "$state" == "available" ]]; then
        size_mb=$(echo "scale=2; $size/1024/1024" | bc)
        print_success "EFS file system: $id is $state (${size_mb}MB used)"
      else
        print_info "EFS file system: $id is $state"
      fi

      # Check mount targets
      MOUNT_TARGETS=$(aws efs describe-mount-targets --file-system-id "$id" --region $AWS_REGION --query "MountTargets[*].[MountTargetId,LifeCycleState,SubnetId]" --output text)

      if [[ -z "$MOUNT_TARGETS" ]]; then
        print_error "  No mount targets found"
      else
        echo "$MOUNT_TARGETS" | while read -r mount_id mount_state subnet; do
          if [[ "$mount_state" == "available" ]]; then
            print_success "  Mount target: $mount_id is $mount_state in subnet $subnet"
          else
            print_info "  Mount target: $mount_id is $mount_state in subnet $subnet"
          fi
        done
      fi
    done

    # Check EFS access points if any
    EFS_ID=$(echo "$EFS_SYSTEMS" | awk '{print $1}' | head -1)
    if [[ -n "$EFS_ID" ]]; then
      ACCESS_POINTS=$(aws efs describe-access-points --file-system-id "$EFS_ID" --region $AWS_REGION --query "AccessPoints[*].[AccessPointId,LifeCycleState]" --output text)

      if [[ -z "$ACCESS_POINTS" ]]; then
        print_info "  No access points configured"
      else
        echo "$ACCESS_POINTS" | while read -r ap_id ap_state; do
          if [[ "$ap_state" == "available" ]]; then
            print_success "  Access point: $ap_id is $ap_state"
          else
            print_info "  Access point: $ap_id is $ap_state"
          fi
        done
      fi
    fi
  fi
}

# Check Lambda functions
check_lambda() {
  print_header "CHECKING LAMBDA FUNCTIONS"

  # List Lambda functions
  FUNCTIONS=$(aws lambda list-functions --region $AWS_REGION --query "Functions[?contains(FunctionName, 'prod-e')].[FunctionName,Runtime,LastModified,State]" --output text)

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
      print_info "  Memory: ${MEMORY}MB, Timeout: ${TIMEOUT}s"

      # Get recent invocations
      INVOCATIONS=$(aws lambda get-function --function-name "$name" --region $AWS_REGION --query "Configuration.LastUpdateStatus" --output text)
      print_info "  Last update status: $INVOCATIONS"
    done
  fi
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

  echo -e "\n${BLUE}===============================================${NC}"
  echo -e "${BLUE}                 CHECK COMPLETE               ${NC}"
  echo -e "${BLUE}===============================================${NC}\n"
}

# Run all checks by default
run_all_checks

# Exit cleanly
exit 0
