#!/bin/bash

# Debug: Confirm the current directory
echo "Current directory: $(pwd)"

# Replace YOUR_AWS_ACCOUNT_ID with your actual AWS account ID
AWS_ACCOUNT_ID="043309339649"

# Import DB subnet group
terraform import aws_db_subnet_group.rds_new-subnet-group_E54AD540 prod-e-rds-subnet-group-new || { echo "Error: Import failed for DB subnet group"; exit 1; }

# Import execution role
terraform import aws_iam_role.ecs_ecs-task-execution-role_3775D793 ecs-task-execution-role || { echo "Error: Import failed for execution role"; exit 1; }

# Import task role
terraform import aws_iam_role.ecs_ecs-task-role_12D46AC3 ecs-task-role || { echo "Error: Import failed for task role"; exit 1; }

# Import ALB
terraform import aws_lb.alb_88D76693 arn:aws:elasticloadbalancing:us-west-2:043309339649:loadbalancer/app/prod-e-alb/28e8b4c5e891545b || { echo "Error: Import failed for ALB"; exit 1; }

# Import target groups
terraform import aws_lb_target_group.alb_ecs-target-group_7A1FFA55 ecs-target-group || { echo "Error: Import failed for ecs target group"; exit 1; }
terraform import aws_lb_target_group.alb_grafana-target-group_B6047762 grafana-tg || { echo "Error: Import failed for grafana target group"; exit 1; }
terraform import aws_lb_target_group.alb_prometheus-target-group_64B90CF3 prometheus-tg || { echo "Error: Import failed for prometheus target group"; exit 1; }

# Import Lambda function
terraform import aws_lambda_function.backup_backup-lambda_62A5F41F prod-e-backup || { echo "Error: Import failed for Lambda function"; exit 1; }

# Import S3 bucket
terraform import aws_s3_bucket.backup_backup-bucket_F99A4016 prod-e-backups || { echo "Error: Import failed for S3 bucket"; exit 1; }
