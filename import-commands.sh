#!/bin/bash

cd "$(dirname "$0")/cdktf.out/stacks/prod-e"

# Import DB subnet group
terraform import -config=. --allow-missing-config aws_db_subnet_group.rds_new-subnet-group_E54AD540 prod-e-rds-subnet-group-new || echo "Import failed for DB subnet group, but continuing..."

# Import execution role
terraform import -config=. --allow-missing-config aws_iam_role.ecs_ecs-task-execution-role_3775D793 ecs-task-execution-role || echo "Import failed for execution role, but continuing..."

# Import task role
terraform import -config=. --allow-missing-config aws_iam_role.ecs_ecs-task-role_12D46AC3 ecs-task-role || echo "Import failed for task role, but continuing..."

# Import ALB
terraform import -config=. --allow-missing-config aws_lb.alb_88D76693 prod-e-alb || echo "Import failed for ALB, but continuing..."

# Import target groups
terraform import -config=. --allow-missing-config aws_lb_target_group.alb_ecs-target-group_7A1FFA55 ecs-target-group || echo "Import failed for ecs target group, but continuing..."
terraform import -config=. --allow-missing-config aws_lb_target_group.alb_grafana-target-group_B6047762 grafana-tg || echo "Import failed for grafana target group, but continuing..."
terraform import -config=. --allow-missing-config aws_lb_target_group.alb_prometheus-target-group_64B90CF3 prometheus-tg || echo "Import failed for prometheus target group, but continuing..."

# Import S3 bucket
terraform import -config=. --allow-missing-config aws_s3_bucket.backup_backup-bucket_F99A4016 prod-e-backups || echo "Import failed for S3 bucket, but continuing..."
