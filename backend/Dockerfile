# Multi-stage build for Node.js application
# Stage 1: Development dependencies for building
FROM node:16 AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies)
RUN npm install

# Copy application code
COPY . .

# Stage 2: Production
FROM node:16-slim

# Set working directory
WORKDIR /app

# Set node environment to production
ENV NODE_ENV=production

# Install essential dependencies for health checks and troubleshooting
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    jq \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev

# Copy application code from builder stage
COPY --from=builder /app/index.js ./

# Create an empty .env file if it doesn't exist in the production environment
RUN touch .env

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nodeuser

# Set ownership
RUN chown -R nodeuser:nodejs /app

# Switch to non-root user
USER nodeuser

# Expose application port
EXPOSE 3000

# Set health check using curl (now available in the image)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Command to run the application
CMD ["node", "index.js"]
