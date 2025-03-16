#!/bin/bash
cd cdktf.out/stacks/prod-e

terraform import aws_db_instance.rds_db_BEC1A0E5 prod-e-db
terraform import aws_ecs_cluster.ecs_cluster_673221EB arn:aws:ecs:us-west-2:043309339649:cluster/prod-e-cluster
terraform import aws_iam_role.ecs_ecs-task-execution-role_3775D793 ecs-task-execution-role
terraform import aws_iam_role.ecs_ecs-task-role_12D46AC3 ecs-task-role
terraform import aws_lb.alb_88D76693 arn:aws:elasticloadbalancing:us-west-2:043309339649:loadbalancer/app/prod-e-alb/698812df871b4c79
terraform import aws_lb_target_group.alb_grafana-target-group_B6047762 arn:aws:elasticloadbalancing:us-west-2:043309339649:targetgroup/grafana-tg/987a76f8e075c3ad
terraform import aws_lb_target_group.alb_prometheus-target-group_64B90CF3 arn:aws:elasticloadbalancing:us-west-2:043309339649:targetgroup/prometheus-tg/2bfa005f80f6fc46
terraform import aws_lb_target_group.alb_ecs-target-group_7A1FFA55 arn:aws:elasticloadbalancing:us-west-2:043309339649:targetgroup/ecs-target-group/0012d807af34a522
terraform import aws_s3_bucket.backup_backup-bucket_F99A4016 prod-e-backups
terraform import aws_lambda_function.backup_backup-lambda_62A5F41F prod-e-backup
