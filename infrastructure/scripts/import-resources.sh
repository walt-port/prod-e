#!/bin/bash

# Script to detect and import existing resources into Terraform state
# Use --ci or --auto-yes for non-interactive mode (for CI/CD pipelines)

# Process command line arguments
CI_MODE=false
for arg in "$@"; do
  case $arg in
    --ci|--auto-yes)
      CI_MODE=true
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

echo "========== AWS Resource Importer for Prod-E Infrastructure =========="
echo "This script will detect existing resources and import them into Terraform state"

# Make sure AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "AWS credentials validated."

# Create a directory to store import commands
IMPORT_DIR="terraform-imports"
mkdir -p $IMPORT_DIR

# Create import command file
IMPORT_COMMANDS_FILE="$IMPORT_DIR/import-commands.sh"
echo "#!/bin/bash" > $IMPORT_COMMANDS_FILE
echo "cd cdktf.out/stacks/prod-e" >> $IMPORT_COMMANDS_FILE
echo "" >> $IMPORT_COMMANDS_FILE

# Check for existing RDS instances
echo "Checking for RDS instances..."
DB_INSTANCE=$(aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier=='prod-e-db'].DBInstanceIdentifier" --output text)
if [ ! -z "$DB_INSTANCE" ]; then
    echo "Found RDS instance: $DB_INSTANCE"
    echo "terraform import aws_db_instance.rds_db_BEC1A0E5 $DB_INSTANCE" >> $IMPORT_COMMANDS_FILE
fi

# Check for existing ECS clusters
echo "Checking for ECS clusters..."
ECS_CLUSTER=$(aws ecs list-clusters --query "clusterArns[?contains(@, 'prod-e-cluster')]" --output text)
if [ ! -z "$ECS_CLUSTER" ]; then
    CLUSTER_NAME=$(basename $ECS_CLUSTER)
    echo "Found ECS cluster: $CLUSTER_NAME"
    echo "terraform import aws_ecs_cluster.ecs_cluster_673221EB $ECS_CLUSTER" >> $IMPORT_COMMANDS_FILE
fi

# Check for existing IAM roles
echo "Checking for IAM roles..."
for ROLE_NAME in "ecs-task-execution-role" "ecs-task-role" "grafana-backup-role"; do
    ROLE=$(aws iam get-role --role-name $ROLE_NAME --query "Role.RoleName" --output text 2>/dev/null || echo "")
    if [ ! -z "$ROLE" ]; then
        echo "Found IAM role: $ROLE"
        case $ROLE_NAME in
            "ecs-task-execution-role")
                echo "terraform import aws_iam_role.ecs_ecs-task-execution-role_3775D793 $ROLE" >> $IMPORT_COMMANDS_FILE
                ;;
            "ecs-task-role")
                echo "terraform import aws_iam_role.ecs_ecs-task-role_12D46AC3 $ROLE" >> $IMPORT_COMMANDS_FILE
                ;;
            "grafana-backup-role")
                echo "terraform import aws_iam_role.backup_grafana-backup-role_FCB42463 $ROLE" >> $IMPORT_COMMANDS_FILE
                ;;
        esac
    fi
done

# Check for existing Load Balancers
echo "Checking for Load Balancers..."
ALB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='prod-e-alb'].LoadBalancerArn" --output text)
if [ ! -z "$ALB_ARN" ]; then
    echo "Found ALB: prod-e-alb"
    echo "terraform import aws_lb.alb_88D76693 $ALB_ARN" >> $IMPORT_COMMANDS_FILE

    # Check for target groups
    echo "Checking for target groups..."
    for TG_NAME in "grafana-tg" "prometheus-tg" "ecs-target-group"; do
        TG_ARN=$(aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='$TG_NAME'].TargetGroupArn" --output text)
        if [ ! -z "$TG_ARN" ]; then
            echo "Found target group: $TG_NAME"
            case $TG_NAME in
                "grafana-tg")
                    echo "terraform import aws_lb_target_group.alb_grafana-target-group_B6047762 $TG_ARN" >> $IMPORT_COMMANDS_FILE
                    ;;
                "prometheus-tg")
                    echo "terraform import aws_lb_target_group.alb_prometheus-target-group_64B90CF3 $TG_ARN" >> $IMPORT_COMMANDS_FILE
                    ;;
                "ecs-target-group")
                    echo "terraform import aws_lb_target_group.alb_ecs-target-group_7A1FFA55 $TG_ARN" >> $IMPORT_COMMANDS_FILE
                    ;;
            esac
        fi
    done
fi

# Check for S3 buckets
echo "Checking for S3 buckets..."
S3_BUCKET=$(aws s3api list-buckets --query "Buckets[?Name=='prod-e-backups'].Name" --output text)
if [ ! -z "$S3_BUCKET" ]; then
    echo "Found S3 bucket: $S3_BUCKET"
    echo "terraform import aws_s3_bucket.backup_backup-bucket_F99A4016 $S3_BUCKET" >> $IMPORT_COMMANDS_FILE
fi

# Check for Lambda functions
echo "Checking for Lambda functions..."
LAMBDA_FUNCTION=$(aws lambda list-functions --query "Functions[?FunctionName=='prod-e-backup'].FunctionName" --output text)
if [ ! -z "$LAMBDA_FUNCTION" ]; then
    echo "Found Lambda function: $LAMBDA_FUNCTION"
    echo "terraform import aws_lambda_function.backup_backup-lambda_62A5F41F $LAMBDA_FUNCTION" >> $IMPORT_COMMANDS_FILE
fi

# Make the import commands file executable
chmod +x $IMPORT_COMMANDS_FILE

echo ""
echo "Import commands prepared in $IMPORT_COMMANDS_FILE"
echo ""

# In CI mode, skip confirmation
if [ "$CI_MODE" = true ]; then
    CONFIRM="y"
else
    # Ask for confirmation before running imports
    read -p "Do you want to run the import commands now? (y/n): " CONFIRM
fi

if [[ $CONFIRM == "y" || $CONFIRM == "Y" ]]; then
    echo "Running import commands..."

    # Set the environment variable to skip creation of existing resources
    export SKIP_EXISTING_RESOURCES=true

    # Synthesize the Terraform code
    npx cdktf synth

    # Run the import commands
    $IMPORT_COMMANDS_FILE

    echo "Import complete. You can now run 'npx cdktf apply' to apply any changes."
else
    echo "Import commands not run. You can run '$IMPORT_COMMANDS_FILE' manually later."
fi
