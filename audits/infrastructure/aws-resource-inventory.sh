#!/bin/bash

# AWS Resource Inventory Script
# This script collects information about AWS resources for infrastructure audits
# Usage: ./aws-resource-inventory.sh [region]

set -e

# Set AWS region
if [ -z "$1" ]; then
    REGION="us-west-2" # Default region
else
    REGION="$1"
fi

# Create output directory
OUTPUT_DIR="inventory-$(date +%Y-%m-%d)"
mkdir -p "$OUTPUT_DIR"

echo "Starting AWS resource inventory for region: $REGION"
echo "Results will be saved to: $OUTPUT_DIR"

# Export AWS region for subsequent commands
export AWS_REGION=$REGION

# Function to run AWS CLI commands and save output
run_aws_command() {
    local service=$1
    local command=$2
    local output_file="$OUTPUT_DIR/${service}-${command}.json"

    echo "Collecting $service $command..."
    aws $service $command --region $REGION > "$output_file"
    echo "✅ Saved to $output_file"
}

# Function to run AWS CLI commands with a specific subcommand
run_aws_subcommand() {
    local service=$1
    local subcommand=$2
    local command=$3
    local output_file="$OUTPUT_DIR/${service}-${subcommand}-${command}.json"

    echo "Collecting $service $subcommand $command..."
    aws $service $subcommand $command --region $REGION > "$output_file"
    echo "✅ Saved to $output_file"
}

echo "=== Network Resources ==="

# VPC
run_aws_command ec2 "describe-vpcs"
run_aws_command ec2 "describe-subnets"
run_aws_command ec2 "describe-route-tables"
run_aws_command ec2 "describe-internet-gateways"
run_aws_command ec2 "describe-nat-gateways"
run_aws_command ec2 "describe-security-groups"

# ELB
run_aws_command elbv2 "describe-load-balancers"
run_aws_command elbv2 "describe-target-groups"
run_aws_command elbv2 "describe-listeners"

echo "=== Compute Resources ==="

# EC2
run_aws_command ec2 "describe-instances"
run_aws_command ec2 "describe-launch-templates"

# ECS
run_aws_command ecs "list-clusters"
run_aws_command ecs "describe-clusters"

# Get all cluster ARNs
CLUSTER_ARNS=$(aws ecs list-clusters --query 'clusterArns[]' --output text --region $REGION)

# For each cluster, get services and tasks
for CLUSTER_ARN in $CLUSTER_ARNS; do
    CLUSTER_NAME=$(basename $CLUSTER_ARN)

    # Get services for this cluster
    run_aws_command ecs "list-services --cluster $CLUSTER_ARN"
    SERVICES=$(aws ecs list-services --cluster $CLUSTER_ARN --query 'serviceArns[]' --output text --region $REGION)

    if [ -n "$SERVICES" ]; then
        # Get service details
        aws ecs describe-services --cluster $CLUSTER_ARN --services $SERVICES --region $REGION > "$OUTPUT_DIR/ecs-describe-services-$CLUSTER_NAME.json"
        echo "✅ Saved to $OUTPUT_DIR/ecs-describe-services-$CLUSTER_NAME.json"
    fi

    # Get task definitions
    run_aws_command ecs "list-task-definitions"

    # Get tasks for this cluster
    run_aws_command ecs "list-tasks --cluster $CLUSTER_ARN"
    TASKS=$(aws ecs list-tasks --cluster $CLUSTER_ARN --query 'taskArns[]' --output text --region $REGION)

    if [ -n "$TASKS" ]; then
        # Get task details
        aws ecs describe-tasks --cluster $CLUSTER_ARN --tasks $TASKS --region $REGION > "$OUTPUT_DIR/ecs-describe-tasks-$CLUSTER_NAME.json"
        echo "✅ Saved to $OUTPUT_DIR/ecs-describe-tasks-$CLUSTER_NAME.json"
    fi
done

# Lambda
run_aws_command lambda "list-functions"

echo "=== Storage Resources ==="

# S3
run_aws_command s3api "list-buckets"

# Get bucket policies, versioning, and encryption for each bucket
BUCKETS=$(aws s3api list-buckets --query 'Buckets[].Name' --output text --region $REGION)
for BUCKET in $BUCKETS; do
    aws s3api get-bucket-policy --bucket $BUCKET --region $REGION > "$OUTPUT_DIR/s3api-get-bucket-policy-$BUCKET.json" 2>/dev/null || echo "No bucket policy for $BUCKET"
    aws s3api get-bucket-versioning --bucket $BUCKET --region $REGION > "$OUTPUT_DIR/s3api-get-bucket-versioning-$BUCKET.json"
    aws s3api get-bucket-encryption --bucket $BUCKET --region $REGION > "$OUTPUT_DIR/s3api-get-bucket-encryption-$BUCKET.json" 2>/dev/null || echo "No encryption for $BUCKET"
done

# RDS
run_aws_command rds "describe-db-instances"
run_aws_command rds "describe-db-subnet-groups"
run_aws_command rds "describe-db-parameter-groups"

echo "=== IAM Resources ==="

# IAM
run_aws_command iam "list-roles"
run_aws_command iam "list-policies"
run_aws_command iam "list-users"
run_aws_command iam "list-groups"

echo "=== CloudWatch Resources ==="

# CloudWatch
run_aws_command logs "describe-log-groups"
run_aws_command cloudwatch "describe-alarms"

echo "=== ECR Resources ==="

# ECR
run_aws_command ecr "describe-repositories"

# Get images for each repository
REPOS=$(aws ecr describe-repositories --query 'repositories[].repositoryName' --output text --region $REGION)
for REPO in $REPOS; do
    aws ecr describe-images --repository-name $REPO --region $REGION > "$OUTPUT_DIR/ecr-describe-images-$REPO.json"
    echo "✅ Saved to $OUTPUT_DIR/ecr-describe-images-$REPO.json"
done

echo "=== Secrets Manager Resources ==="

# Secrets Manager
run_aws_command secretsmanager "list-secrets"

echo "=== Cost Explorer ==="

# Get cost for the last month (requires Cost Explorer to be enabled)
START_DATE=$(date -d "1 month ago" +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

aws ce get-cost-and-usage \
    --time-period Start=${START_DATE},End=${END_DATE} \
    --granularity MONTHLY \
    --metrics "BlendedCost" "UnblendedCost" "UsageQuantity" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --region $REGION > "$OUTPUT_DIR/cost-explorer-monthly.json" 2>/dev/null || echo "Cost Explorer not available or not enabled"

echo "=== Generating Summary ==="

# Generate summary
echo "# AWS Resource Inventory Summary" > "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "Date: $(date)" >> "$OUTPUT_DIR/summary.md"
echo "Region: $REGION" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# VPC Summary
VPC_COUNT=$(jq '.Vpcs | length' "$OUTPUT_DIR/ec2-describe-vpcs.json")
SUBNET_COUNT=$(jq '.Subnets | length' "$OUTPUT_DIR/ec2-describe-subnets.json")
SG_COUNT=$(jq '.SecurityGroups | length' "$OUTPUT_DIR/ec2-describe-security-groups.json")

echo "## Network Resources" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "- VPCs: $VPC_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "- Subnets: $SUBNET_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "- Security Groups: $SG_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# EC2 Summary
INSTANCE_COUNT=$(jq '.Reservations[].Instances | length' "$OUTPUT_DIR/ec2-describe-instances.json" | jq -s 'add // 0')
echo "## Compute Resources" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "- EC2 Instances: $INSTANCE_COUNT" >> "$OUTPUT_DIR/summary.md"

# ECS Summary
CLUSTER_COUNT=$(jq '.clusterArns | length' "$OUTPUT_DIR/ecs-list-clusters.json")
echo "- ECS Clusters: $CLUSTER_COUNT" >> "$OUTPUT_DIR/summary.md"

# Lambda Summary
LAMBDA_COUNT=$(jq '.Functions | length' "$OUTPUT_DIR/lambda-list-functions.json")
echo "- Lambda Functions: $LAMBDA_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# S3 Summary
BUCKET_COUNT=$(jq '.Buckets | length' "$OUTPUT_DIR/s3api-list-buckets.json")
echo "## Storage Resources" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "- S3 Buckets: $BUCKET_COUNT" >> "$OUTPUT_DIR/summary.md"

# RDS Summary
RDS_COUNT=$(jq '.DBInstances | length' "$OUTPUT_DIR/rds-describe-db-instances.json")
echo "- RDS Instances: $RDS_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# IAM Summary
ROLE_COUNT=$(jq '.Roles | length' "$OUTPUT_DIR/iam-list-roles.json")
POLICY_COUNT=$(jq '.Policies | length' "$OUTPUT_DIR/iam-list-policies.json")
USER_COUNT=$(jq '.Users | length' "$OUTPUT_DIR/iam-list-users.json")
echo "## IAM Resources" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "- IAM Roles: $ROLE_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "- IAM Policies: $POLICY_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "- IAM Users: $USER_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# CloudWatch Summary
LOG_GROUP_COUNT=$(jq '.logGroups | length' "$OUTPUT_DIR/logs-describe-log-groups.json")
ALARM_COUNT=$(jq '.MetricAlarms | length' "$OUTPUT_DIR/cloudwatch-describe-alarms.json")
echo "## CloudWatch Resources" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "- Log Groups: $LOG_GROUP_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "- Alarms: $ALARM_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# ECR Summary
ECR_REPO_COUNT=$(jq '.repositories | length' "$OUTPUT_DIR/ecr-describe-repositories.json")
echo "## ECR Resources" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "- ECR Repositories: $ECR_REPO_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# Secrets Manager Summary
SECRET_COUNT=$(jq '.SecretList | length' "$OUTPUT_DIR/secretsmanager-list-secrets.json")
echo "## Secrets Manager Resources" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "- Secrets: $SECRET_COUNT" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

echo "AWS resource inventory completed! Results saved to $OUTPUT_DIR"
echo "Summary available at $OUTPUT_DIR/summary.md"
