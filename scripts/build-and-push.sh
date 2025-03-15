#!/bin/bash
# Script to build and push Docker image(s) to Amazon ECR

# Exit on error
set -e

# Configuration
REGION="us-west-2"
DEFAULT_IMAGE_TAG="latest"

# Print usage information
usage() {
  echo "Usage: $0 [OPTIONS] IMAGE_NAME"
  echo "Build and push Docker images to Amazon ECR"
  echo ""
  echo "Options:"
  echo "  -d, --directory DIR   Source directory containing Dockerfile (default: ../backend for backend image)"
  echo "  -t, --tag TAG         Image tag (default: latest)"
  echo "  -h, --help            Display this help message"
  echo ""
  echo "Available image names:"
  echo "  backend               Backend API service"
  echo "  grafana               Grafana monitoring dashboard"
  echo "  prometheus            Prometheus monitoring service"
  echo ""
  echo "Examples:"
  echo "  $0 backend            Build and push backend image with default settings"
  echo "  $0 -t v1.0.0 backend  Build and push backend image with tag v1.0.0"
  echo "  $0 grafana            Build and push Grafana image"
}

# Process command line arguments
IMAGE_TAG="$DEFAULT_IMAGE_TAG"
SOURCE_DIR=""
IMAGE_NAME=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--directory)
      SOURCE_DIR="$2"
      shift 2
      ;;
    -t|--tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      IMAGE_NAME="$1"
      shift
      ;;
  esac
done

# Validate image name
if [ -z "$IMAGE_NAME" ]; then
  echo "Error: No image name specified"
  usage
  exit 1
fi

# Set ECR repository name based on image name
case $IMAGE_NAME in
  backend)
    ECR_REPO_NAME="prod-e-backend"
    SOURCE_DIR=${SOURCE_DIR:-"../backend"}
    ;;
  grafana)
    ECR_REPO_NAME="prod-e-grafana"
    SOURCE_DIR=${SOURCE_DIR:-"../monitoring/grafana"}
    ;;
  prometheus)
    ECR_REPO_NAME="prod-e-prometheus"
    SOURCE_DIR=${SOURCE_DIR:-"../monitoring/prometheus"}
    ;;
  *)
    echo "Error: Unknown image name '$IMAGE_NAME'"
    usage
    exit 1
    ;;
esac

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
  echo "Error: Failed to get AWS account ID. Make sure AWS CLI is configured properly."
  exit 1
fi

# Build the full ECR repository URI
ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo "===== Building and Pushing to ECR Repository: ${ECR_REPO_URI} ====="

# Change to the source directory
echo "Using source directory: $SOURCE_DIR"
cd "$(dirname "$0")/$SOURCE_DIR"

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
