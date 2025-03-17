#!/bin/bash

echo "terraform import --allow-missing-config aws_db_subnet_group.rds_new-subnet-group_E54AD540 prod-e-rds-subnet-group-new"
echo "terraform import --allow-missing-config aws_iam_role.ecs_ecs-task-execution-role_3775D793 ecs-task-execution-role"
echo "terraform import --allow-missing-config aws_iam_role.ecs_ecs-task-role_12D46AC3 ecs-task-role"
echo "terraform import --allow-missing-config aws_lb.alb_88D76693 prod-e-alb"
echo "terraform import --allow-missing-config aws_lb_target_group.alb_ecs-target-group_7A1FFA55 ecs-target-group"
echo "terraform import --allow-missing-config aws_lb_target_group.alb_grafana-target-group_B6047762 grafana-tg"
echo "terraform import --allow-missing-config aws_lb_target_group.alb_prometheus-target-group_64B90CF3 prometheus-tg"
echo "terraform import --allow-missing-config aws_s3_bucket.backup_backup-bucket_F99A4016 prod-e-backups"
