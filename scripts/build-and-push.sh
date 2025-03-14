#!/bin/bash
# Script to build and push Docker image to Amazon ECR

# Exit on error
set -e

# Configuration
REGION="us-west-2"
ECR_REPO_NAME="prod-e-backend"
IMAGE_TAG="latest"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
  echo "Error: Failed to get AWS account ID. Make sure AWS CLI is configured properly."
  exit 1
fi

# Build the full ECR repository URI
ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo "===== Building and Pushing to ECR Repository: ${ECR_REPO_URI} ====="

# Move to the backend directory
cd "$(dirname "$0")/../backend"

# Build the Docker image
echo "Building Docker image..."
docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .

# Log in to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Create ECR repository if it doesn't exist
echo "Making sure ECR repository exists..."
aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${REGION} || \
  aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${REGION}

# Tag the image for ECR
echo "Tagging image for ECR..."
docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_REPO_URI}:${IMAGE_TAG}

# Push the image to ECR
echo "Pushing image to ECR..."
docker push ${ECR_REPO_URI}:${IMAGE_TAG}

echo "===== Successfully pushed ${ECR_REPO_URI}:${IMAGE_TAG} to ECR ====="

# Return to original directory
cd - > /dev/null

echo "Next steps:"
echo "1. Run 'npm run deploy' to update the infrastructure with the new container image."
echo "2. The ECS service will automatically use the new image."
