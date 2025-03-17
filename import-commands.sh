#!/bin/bash

# Debug: Confirm the current directory
echo "Current directory: $(pwd)"

# Replace YOUR_AWS_ACCOUNT_ID with your actual AWS account ID
AWS_ACCOUNT_ID="043309339649"

# Import DB subnet group
terraform import aws_db_subnet_group.prode_rds_newsubnetgroup_8B244C0C prod-e-rds-subnet-group-new || { echo "Error: Import failed for DB subnet group"; exit 1; }

# Import execution role
terraform import aws_iam_role.prode_ecs_ecstaskexecutionrole_20EAF6F9 "arn:aws:iam::$AWS_ACCOUNT_ID:role/ecs-task-execution-role" || { echo "Error: Import failed for execution role"; exit 1; }

# Import task role
terraform import aws_iam_role.prode_ecs_ecstaskrole_83A127B2 "arn:aws:iam::$AWS_ACCOUNT_ID:role/ecs-task-role" || { echo "Error: Import failed for task role"; exit 1; }

# Import ALB
terraform import aws_lb.prode_alb_5B6BC7FD prod-e-alb || { echo "Error: Import failed for ALB"; exit 1; }

# Import target groups
terraform import aws_lb_target_group.prode_alb_ecstargetgroup_D11F7D5C ecs-target-group || { echo "Error: Import failed for ecs target group"; exit 1; }
terraform import aws_lb_target_group.prode_alb_grafanatargetgroup_F3AF7448 grafana-tg || { echo "Error: Import failed for grafana target group"; exit 1; }
terraform import aws_lb_target_group.prode_alb_prometheustargetgroup_F7AD68CC prometheus-tg || { echo "Error: Import failed for prometheus target group"; exit 1; }

# Import Lambda function
terraform import aws_lambda_function.prode_backup_backuplambda_D9B46980 prod-e-backup || { echo "Error: Import failed for Lambda function"; exit 1; }

# Import S3 bucket
terraform import aws_s3_bucket.prode_backup_backupbucket_A17FE2F3 prod-e-backups || { echo "Error: Import failed for S3 bucket"; exit 1; }
