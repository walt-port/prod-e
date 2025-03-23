require('dotenv').config();
const express = require('express');
const promClient = require('prom-client');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const { Client } = require('@aws-sdk/client-secrets-manager');

const app = express();
const port = process.env.PORT || 3000;
const secretsManager = new Client({ region: process.env.AWS_REGION || 'us-west-2' });

const register = new promClient.Registry();
promClient.collectDefaultMetrics({
  prefix: process.env.METRICS_PREFIX || 'prod_e_',
  register,
});

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

register.registerMetric(httpRequestDurationMicroseconds);
register.registerMetric(httpRequestCounter);

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: { title: 'Production Experience API', version: '1.0.0', description: 'API for monitoring and metrics' },
    servers: [{ url: `http://localhost:${port}`, description: 'Development server' }],
  },
  apis: ['./index.js'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

async function getDbCredentials() {
  const secretId = process.env.DB_CREDENTIALS_SECRET_NAME || 'prod-e-db-credentials';
  try {
    const { SecretString } = await secretsManager.getSecretValue({ SecretId: secretId });
    return JSON.parse(SecretString);
  } catch (err) {
    console.error('Error fetching DB credentials:', err);
    throw err;
  }
}

let pool;
async function initializeDatabase() {
  const { Pool } = require('pg');
  const dbConfig = await getDbCredentials();
  pool = new Pool({
    host: dbConfig.host,
    port: dbConfig.port,
    database: dbConfig.dbname,
    user: dbConfig.username,
    password: dbConfig.password,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  });

  const client = await pool.connect();
  try {
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
    console.log('Database initialized');
  } finally {
    client.release();
  }
}

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', async () => {
    const duration = (Date.now() - start) / 1000;
    if (req.path !== '/metrics') {
      httpRequestDurationMicroseconds.labels(req.method, req.path, res.statusCode).observe(duration);
      httpRequestCounter.labels(req.method, req.path, res.statusCode).inc();
      if (req.path !== '/health') {
        const client = await pool.connect();
        try {
          await client.query(
            'INSERT INTO metrics(endpoint, method, status_code, duration_ms) VALUES($1, $2, $3, $4)',
            [req.path, req.method, res.statusCode, duration * 1000]
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

initializeDatabase().catch(err => console.error('Database init failed:', err));

app.get('/health', async (req, res) => {
  const response = { status: 'ok', timestamp: new Date().toISOString() };
  try {
    const client = await pool.connect();
    try {
      await client.query('SELECT NOW()');
      await client.query(
        'INSERT INTO metrics(endpoint, method, status_code, duration_ms) VALUES($1, $2, $3, $4)',
        ['/health', 'GET', 200, 0]
      );
      response.database = 'connected';
      res.json(response);
    } finally {
      client.release();
    }
  } catch (err) {
    console.error('Health check failed:', err);
    res.status(500).json({ status: 'error', message: 'Database connection failed', database: 'disconnected' });
  }
});

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    console.error('Error generating metrics:', err);
    res.status(500).end('Error generating metrics');
  }
});

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
    console.log(`Metrics at http://localhost:${port}${process.env.METRICS_PATH || '/metrics'}`);
    console.log(`Health check at http://localhost:${port}/health`);
    console.log(`API docs at http://localhost:${port}/api-docs`);
  });
}

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down');
  pool.end().then(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});

module.exports = app;
