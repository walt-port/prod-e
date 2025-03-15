# Backend Docker Configuration

## Overview

The backend service is containerized using Docker to provide a consistent, reproducible environment for the application. The Docker image is built and stored in Amazon ECR for deployment to ECS.

## Dockerfile Structure

The backend Dockerfile uses a multi-stage build process to create an efficient, secure image:

```dockerfile
# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:18-slim
WORKDIR /app

# Install health check dependencies and security updates
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy built application
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./

# Configuration
ENV NODE_ENV=production
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start application
CMD ["node", "dist/main"]
```

Key features:

- **Multi-stage build**: Separates build environment from runtime environment
- **Security Enhancements**: Uses slim variant and removes unnecessary dependencies
- **Health Check**: Includes curl for health checks to support ECS health monitoring
- **Minimal Dependencies**: Only includes production-necessary packages

## Building and Deployment

### Building Locally

```bash
docker build -t prod-e-backend:latest .
```

### Pushing to ECR

```bash
# Authenticate with ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 043309339649.dkr.ecr.us-west-2.amazonaws.com

# Tag image
docker tag prod-e-backend:latest 043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:latest

# Push image
docker push 043309339649.dkr.ecr.us-west-2.amazonaws.com/prod-e-backend:latest
```

## Best Practices

- Always include essential utilities for health checking (curl, wget)
- Keep the image as small as possible by using multi-stage builds
- Remove unnecessary build artifacts and package manager caches
- Set appropriate security contexts and non-root users
- Regularly update base images for security patches
- Use specific version tags rather than 'latest' for production deployments
- Include proper health check configuration in the Dockerfile

## Health Check

The container is configured with a health check that uses curl to verify the application is responding properly. This is crucial for ECS task health monitoring.

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1
```

This configuration is mirrored in the ECS task definition to ensure consistent health evaluation.
