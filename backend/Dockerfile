# Single-stage build
FROM node:18
WORKDIR /app
ENV NODE_ENV=production

# Install netcat for healthcheck and other potential dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY package*.json ./
COPY index.js ./
# Add other source files if needed, e.g., COPY src/ ./src/

# Install production dependencies
RUN npm install --omit=dev

# Set up non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nodeuser
# Ensure app directory ownership is correct *before* switching user
RUN chown -R nodeuser:nodejs /app
USER nodeuser

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD nc -z localhost 3000 || exit 1
CMD ["node", "index.js"]
