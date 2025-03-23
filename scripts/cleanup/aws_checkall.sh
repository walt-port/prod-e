#!/bin/bash

REGION="us-west-2"
echo "Verifying FULL AWS cleanup in $REGION..."

# ECS - Clusters, Services, Task Definitions
echo "Checking ECS..."
ecs_clusters=$(aws ecs list-clusters --region $REGION)
[ "$ecs_clusters" == '{"clusterArns": []}' ] && echo "✓ No ECS clusters" || echo "✗ ECS clusters remain: $ecs_clusters"
ecs_tasks=$(aws ecs list-task-definitions --region $REGION)
[ "$ecs_tasks" == '{"taskDefinitionArns": []}' ] && echo "✓ No ECS task definitions" || echo "✗ ECS task definitions remain: $ecs_tasks"

# ALB - Load Balancers, Target Groups
echo "Checking ALB..."
albs=$(aws elbv2 describe-load-balancers --region $REGION)
[ "$albs" == '{"LoadBalancers": []}' ] && echo "✓ No ALBs" || echo "✗ ALBs remain: $albs"
tgs=$(aws elbv2 describe-target-groups --region $REGION)
[ "$tgs" == '{"TargetGroups": []}' ] && echo "✓ No Target Groups" || echo "✗ Target Groups remain: $tgs"

# EC2 - VPCs, Subnets, Route Tables, SGs, EIPs, NACLs, Endpoints
echo "Checking EC2..."
vpcs=$(aws ec2 describe-vpcs --region $REGION)
[ "$vpcs" == '{"Vpcs": []}' ] && echo "✓ No VPCs" || echo "✗ VPCs remain: $vpcs"
subnets=$(aws ec2 describe-subnets --region $REGION)
[ "$subnets" == '{"Subnets": []}' ] && echo "✓ No Subnets" || echo "✗ Subnets remain: $subnets"
route_tables=$(aws ec2 describe-route-tables --region $REGION)
[ "$route_tables" == '{"RouteTables": []}' ] && echo "✓ No Route Tables" || echo "✗ Route Tables remain: $route_tables"
sgs=$(aws ec2 describe-security-groups --region $REGION)
[ "$sgs" == '{"SecurityGroups": []}' ] && echo "✓ No Security Groups" || echo "✗ Security Groups remain: $sgs"
eips=$(aws ec2 describe-addresses --region $REGION)
[ "$eips" == '{"Addresses": []}' ] && echo "✓ No EIPs" || echo "✗ EIPs remain: $eips"
nacls=$(aws ec2 describe-network-acls --region $REGION)
[ "$nacls" == '{"NetworkAcls": []}' ] && echo "✓ No Network ACLs" || echo "✗ Network ACLs remain: $nacls"
endpoints=$(aws ec2 describe-vpc-endpoints --region $REGION)
[ "$endpoints" == '{"VpcEndpoints": []}' ] && echo "✓ No VPC Endpoints" || echo "✗ VPC Endpoints remain: $endpoints"

# Lambda
echo "Checking Lambda..."
lambdas=$(aws lambda list-functions --region $REGION)
[ "$lambdas" == '{"Functions": []}' ] && echo "✓ No Lambda functions" || echo "✗ Lambdas remain: $lambdas"

# S3
echo "Checking S3..."
buckets=$(aws s3 ls --region $REGION)
[ -z "$buckets" ] && echo "✓ No S3 buckets" || echo "✗ Buckets remain: $buckets"

# IAM - Roles, Policies
echo "Checking IAM..."
roles=$(aws iam list-roles)
echo "IAM Roles (full list, check for custom 'ecs', 'grafana', 'terraform'): $roles"
policies=$(aws iam list-policies --scope Local)
[ "$policies" == '{"Policies": []}' ] && echo "✓ No custom IAM policies" || echo "✗ Custom policies remain: $policies"

# CloudWatch Logs
echo "Checking CloudWatch Logs..."
logs=$(aws logs describe-log-groups --region $REGION)
[ "$logs" == '{"logGroups": []}' ] && echo "✓ No CloudWatch log groups" || echo "✗ Log groups remain: $logs"

# RDS - Subnet Groups, Instances
echo "Checking RDS..."
subnet_groups=$(aws rds describe-db-subnet-groups --region $REGION)
[ "$subnet_groups" == '{"DBSubnetGroups": []}' ] && echo "✓ No RDS subnet groups" || echo "✗ Subnet groups remain: $subnet_groups"
db_instances=$(aws rds describe-db-instances --region $REGION)
[ "$db_instances" == '{"DBInstances": []}' ] && echo "✓ No RDS instances" || echo "✗ DB instances remain: $db_instances"

# DynamoDB
echo "Checking DynamoDB..."
dynamodb_tables=$(aws dynamodb list-tables --region $REGION)
[ "$dynamodb_tables" == '{"TableNames": []}' ] && echo "✓ No DynamoDB tables" || echo "✗ DynamoDB tables remain: $dynamodb_tables"

echo "Cleanup verification complete! Check above for any ✗s or unexpected resources."
