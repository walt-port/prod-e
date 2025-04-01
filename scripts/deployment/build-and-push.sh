#!/bin/bash
set -e

# Load .env
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found"
  exit 1
fi

# Config from .env
REGION="${AWS_REGION:-us-west-2}"
ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
TAG="${TAG:-latest}"

# Determine the directory containing the Dockerfiles (assuming it's always 'backend')
BUILD_CONTEXT_DIR="backend"

# Map service name (derived from repo) to its specific Dockerfile within BUILD_CONTEXT_DIR
declare -A DOCKERFILES=(
  ["backend"]="Dockerfile"
  ["grafana"]="Dockerfile.grafana"
  ["prometheus"]="Dockerfile.prometheus"
)

REPOS=("prod-e-backend" "prod-e-grafana" "prod-e-prometheus")

# Get absolute path of the script's directory to handle cd correctly
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WORKSPACE_ROOT=$(dirname "$SCRIPT_DIR")/.. # Assumes script is in scripts/deployment

# Build and push all images
for repo in "${REPOS[@]}"; do
  service_name="${repo#prod-e-}" # Extract service name (backend, grafana, prometheus)
  dockerfile_name="${DOCKERFILES[$service_name]}"

  if [ -z "$dockerfile_name" ]; then
    echo "Error: Dockerfile mapping not found for service '$service_name' (repo '$repo')"
    exit 1
  fi

  dockerfile_path="${WORKSPACE_ROOT}/${BUILD_CONTEXT_DIR}/${dockerfile_name}"
  build_context_path="${WORKSPACE_ROOT}/${BUILD_CONTEXT_DIR}"

  echo "===== Building $repo from ${dockerfile_name} in ${BUILD_CONTEXT_DIR} ====="

  uri="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${repo}"

  echo "Building $repo:$TAG using ${dockerfile_path} with context ${build_context_path}..."
  # Use -f to specify the Dockerfile, build context is the backend directory
  docker build -t "$repo:$TAG" -f "$dockerfile_path" "$build_context_path"

  echo "Logging into ECR..."
  aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$uri"

  echo "Ensuring ECR repo exists..."
  aws ecr describe-repositories --repository-names "$repo" --region "$REGION" > /dev/null 2>&1 || \
    aws ecr create-repository --repository-name "$repo" --region "$REGION" > /dev/null

  echo "Tagging $repo:$TAG as $uri:$TAG..."
  docker tag "$repo:$TAG" "$uri:$TAG"

  echo "Pushing $uri:$TAG..."
  docker push "$uri:$TAG"

  echo "===== Pushed $uri:$TAG =====
"

done

echo "Build and push complete!"
