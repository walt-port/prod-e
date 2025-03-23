# Multi-stage build for Node.js application
# Stage 1: Build
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY index.js .

# Stage 2: Production
FROM node:18-slim
WORKDIR /app
ENV NODE_ENV=production

# Install netcat for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install --omit=dev
COPY --from=builder /app/index.js ./

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nodeuser
RUN chown -R nodeuser:nodejs /app
USER nodeuser

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD nc -z localhost 3000 || exit 1
CMD ["node", "index.js"]
