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

# Image configs
declare -A IMAGES=(
  ["backend"]="backend"
  ["grafana"]="backend"
  ["prometheus"]="backend"
)
REPOS=("prod-e-backend" "prod-e-grafana" "prod-e-prometheus")

# Build and push all images
for repo in "${REPOS[@]}"; do
  dir="${IMAGES[${repo#prod-e-}]}"
  echo "===== Building $repo ====="
  cd "$dir" || { echo "Dir $dir not found"; exit 1; }
  uri="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${repo}"

  echo "Building $repo:$TAG in $dir..."
  docker build -t "$repo:$TAG" .

  echo "Logging into ECR..."
  aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$uri"

  echo "Ensuring ECR repo exists..."
  aws ecr describe-repositories --repository-names "$repo" --region "$REGION" 2>/dev/null || \
    aws ecr create-repository --repository-name "$repo" --region "$REGION"

  echo "Tagging $repo:$TAG as $uri:$TAG..."
  docker tag "$repo:$TAG" "$uri:$TAG"

  echo "Pushing $uri:$TAG..."
  docker push "$uri:$TAG"

  echo "===== Pushed $uri:$TAG ====="
  cd - > /dev/null
done

echo "Build and push complete!"
