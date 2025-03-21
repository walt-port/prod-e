/**
 * Backend API Service for Production Experience Showcase
 *
 * This service provides endpoints for health checks and Prometheus metrics,
 * connects to a PostgreSQL database, and logs request data.
 */

// Load environment variables
require('dotenv').config();

// Import dependencies
const express = require('express');
const promClient = require('prom-client');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const AWS = require('aws-sdk');

// Create Express application
const app = express();
const port = process.env.PORT || 3000;

// Determine if we should connect to the database
const shouldConnectToDatabase = process.env.NODE_ENV !== 'test';

// Configure AWS SDK
if (process.env.NODE_ENV === 'production') {
  AWS.config.update({ region: process.env.AWS_REGION || 'us-west-2' });
}

// Configure Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({
  prefix: process.env.METRICS_PREFIX || 'prod_e_',
  register,
});

// Create custom Prometheus metrics
const httpRequestDurationMicroseconds = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5],
});

const httpRequestCounter = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

// Register custom metrics
register.registerMetric(httpRequestDurationMicroseconds);
register.registerMetric(httpRequestCounter);

// Configure Swagger documentation
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Production Experience API',
      version: '1.0.0',
      description: 'API for monitoring and metrics collection',
    },
    servers: [
      {
        url: `http://localhost:${port}`,
        description: 'Development server',
      },
    ],
  },
  apis: ['./index.js'], // Path to the API docs
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

// Configure PostgreSQL connection if not in test mode
let pool;
let dbConfig = {};

async function getDbCredentials() {
  if (process.env.NODE_ENV === 'production') {
    // In production, get credentials from AWS Secrets Manager
    const secretsManager = new AWS.SecretsManager();
    try {
      const secretId = process.env.DB_CREDENTIALS_SECRET_NAME || 'prod-e-db-credentials';
      const data = await secretsManager.getSecretValue({ SecretId: secretId }).promise();
      const secret = JSON.parse(data.SecretString);

      return {
        host: secret.host || process.env.DB_HOST,
        port: secret.port || process.env.DB_PORT,
        database: secret.dbname || process.env.DB_NAME,
        user: secret.username || process.env.DB_USER,
        password: secret.password || process.env.DB_PASSWORD,
      };
    } catch (err) {
      console.error('Error retrieving database credentials from Secrets Manager:', err);
      console.warn('Falling back to environment variables for database configuration');

      // Fall back to environment variables
      return {
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        database: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
      };
    }
  } else {
    // In non-production environments, use environment variables
    return {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    };
  }
}

// Initialize database connection
async function initializeDatabaseConnection() {
  if (shouldConnectToDatabase) {
    const { Pool } = require('pg');
    dbConfig = await getDbCredentials();

    pool = new Pool({
      host: dbConfig.host,
      port: dbConfig.port,
      database: dbConfig.database,
      user: dbConfig.user,
      password: dbConfig.password,
      max: 20, // Maximum number of clients in the pool
      idleTimeoutMillis: 30000, // How long a client is allowed to remain idle before being closed
      connectionTimeoutMillis: 2000, // How long to wait for a connection
    });

    console.log(
      `Database connection initialized to ${dbConfig.host}:${dbConfig.port}/${dbConfig.database} as ${dbConfig.user}`
    );
  }
}

// Middleware to measure request duration
app.use((req, res, next) => {
  const start = Date.now();

  // Add listener for response finish event
  res.on('finish', async () => {
    const duration = (Date.now() - start) / 1000; // Convert to seconds

    // Exclude metrics endpoint from metrics to avoid circular references
    if (req.path !== '/metrics') {
      httpRequestDurationMicroseconds
        .labels(req.method, req.path, res.statusCode)
        .observe(duration);

      httpRequestCounter.labels(req.method, req.path, res.statusCode).inc();

      // Log all non-metrics requests to the database
      if (shouldConnectToDatabase && req.path !== '/health') {
        // Skip /health as it's logged separately
        const client = await pool.connect();
        try {
          await client.query(
            'INSERT INTO metrics(endpoint, method, status_code, duration_ms) VALUES($1, $2, $3, $4)',
            [req.path, req.method, res.statusCode, duration * 1000] // Convert to ms
          );
        } catch (err) {
          console.error('Error logging to DB:', err);
        } finally {
          client.release();
        }
      }
    }
  });

  next();
});

// Create metrics table if it doesn't exist
async function initializeDatabase() {
  if (!shouldConnectToDatabase) {
    console.log('Skipping database initialization in test mode');
    return;
  }

  await initializeDatabaseConnection();

  let client;
  try {
    client = await pool.connect();
    try {
      // Create metrics table if it doesn't exist
      await client.query(`
        CREATE TABLE IF NOT EXISTS metrics (
          id SERIAL PRIMARY KEY,
          endpoint VARCHAR(255) NOT NULL,
          method VARCHAR(50) NOT NULL,
          status_code INTEGER NOT NULL,
          duration_ms FLOAT NOT NULL,
          timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Database initialized successfully');
    } finally {
      if (client) client.release();
    }
  } catch (err) {
    console.error('Error initializing database:', err);
  }
}

// Initialize database
initializeDatabase().catch(err => {
  console.error('Failed to initialize database:', err);
});

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Service health check
 *     description: Returns the current status of the service
 *     responses:
 *       200:
 *         description: Service is running correctly
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: ok
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 */
app.get('/health', async (req, res) => {
  const response = {
    status: 'ok',
    timestamp: new Date().toISOString(),
  };

  if (!shouldConnectToDatabase) {
    response.database = 'skipped (test mode)';
    return res.json(response);
  }

  try {
    // Check DB connection
    const client = await pool.connect();
    try {
      await client.query('SELECT NOW()');

      // Log request to database
      await client.query(
        'INSERT INTO metrics(endpoint, method, status_code, duration_ms) VALUES($1, $2, $3, $4)',
        ['/health', 'GET', 200, 0]
      );

      // Return successful response
      response.database = 'connected';
      res.json(response);
    } finally {
      client.release();
    }
  } catch (err) {
    console.error('Health check failed:', err);
    response.status = 'error';
    response.message = 'Database connection failed';
    response.database = 'disconnected';
    res.status(500).json(response);
  }
});

/**
 * @swagger
 * /metrics:
 *   get:
 *     summary: Prometheus metrics endpoint
 *     description: Provides Prometheus metrics for service monitoring
 *     responses:
 *       200:
 *         description: Metrics in Prometheus format
 *         content:
 *           text/plain:
 *             schema:
 *               type: string
 */
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    console.error('Error generating metrics:', err);
    res.status(500).end('Error generating metrics');
  }
});

// Serve Swagger documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Start the server only if not being required (i.e., not in a test)
if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
    console.log(`Metrics available at http://localhost:${port}/metrics`);
    console.log(`Health check available at http://localhost:${port}/health`);
    console.log(`API documentation available at http://localhost:${port}/api-docs`);
  });
}

// Handle process termination gracefully
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  pool.end().then(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});

// Export app for testing purposes
module.exports = app;
