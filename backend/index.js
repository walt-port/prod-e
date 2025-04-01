require('dotenv').config();
const express = require('express');
const promClient = require('prom-client');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
// Import the correct client class name AND the command
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const app = express();
const port = process.env.PORT || 3000;

// Instantiate using the correct class name
const secretsManager = new SecretsManagerClient({ region: process.env.AWS_REGION || 'us-west-2' });

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
    info: {
      title: 'Production Experience API',
      version: '1.0.0',
      description: 'API for monitoring and metrics',
    },
    servers: [{ url: `http://localhost:${port}`, description: 'Development server' }],
  },
  apis: ['./index.js'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

async function getDbCredentials() {
  const secretId = process.env.DB_CREDENTIALS_SECRET_NAME || 'prod-e-db-credentials';
  console.log(`Fetching credentials from Secrets Manager: ${secretId}`);
  const command = new GetSecretValueCommand({ SecretId: secretId });
  try {
    // Send the command using the client
    const data = await secretsManager.send(command);
    if (data.SecretString) {
      return JSON.parse(data.SecretString);
    } else {
      // Handle case where secret is binary (though unlikely for DB credentials)
      // let buff = Buffer.from(data.SecretBinary, 'base64');
      // decodedBinarySecret = buff.toString('ascii');
      throw new Error(`Secret ${secretId} does not contain a SecretString.`);
    }
  } catch (err) {
    console.error('Error fetching DB credentials from Secrets Manager:', err);
    throw err;
  }
}

let pool;
async function initializeDatabase() {
  const { Pool } = require('pg');
  const dbConfig = await getDbCredentials();
  // Log the config values separately for clarity
  console.log(`Initializing connection pool with config:
    Host: ${dbConfig.host}
    Port: ${dbConfig.port}
    DB: ${dbConfig.dbname}
    User: ${dbConfig.username}`);
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

  // Add error listener to the pool
  pool.on('error', (err, client) => {
    console.error('Unexpected error on idle client', err);
    // Optional: attempt to remove the client from the pool or exit
    // process.exit(-1);
  });

  // Test connection and run initial query
  let client;
  try {
    console.log('Connecting client to create table if needed...');
    client = await pool.connect(); // Test the connection
    console.log('Client connected. Running CREATE TABLE IF NOT EXISTS...');
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
    console.log('Initial DB query successful (table ensured).');
    // Optionally run a SELECT 1 to be absolutely sure
    // await client.query('SELECT 1');
    // console.log('Test SELECT 1 successful.');
  } catch (err) {
    console.error('Database initialization query failed:', err);
    // If initialization fails, we should probably prevent the server from starting.
    throw err; // Re-throw the error to be caught by startServer
  } finally {
    if (client) {
      client.release();
      console.log('Initialization client released.');
    }
  }
  console.log('Database pool initialization seems complete.');
  // No explicit return needed, promise resolves successfully if no error thrown
}

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', async () => {
    const duration = (Date.now() - start) / 1000;
    if (req.path !== '/metrics') {
      httpRequestDurationMicroseconds
        .labels(req.method, req.path, res.statusCode)
        .observe(duration);
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

app.get('/health', async (req, res) => {
  const response = { status: 'ok', timestamp: new Date().toISOString() };
  if (!pool) {
    console.error('Health check probe failed: Database pool not initialized yet.');
    return res
      .status(503)
      .json({ status: 'error', message: 'Database initializing', database: 'initializing' });
  }
  response.database = 'pool_initialized';
  res.json(response);
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

async function startServer() {
  try {
    console.log('Initializing database...');
    await initializeDatabase();
    console.log('Database initialization complete.');

    if (require.main === module) {
      app.listen(port, () => {
        console.log(`Server running on port ${port}`);
        console.log(`Metrics at http://localhost:${port}${process.env.METRICS_PATH || '/metrics'}`);
        console.log(`Health check at http://localhost:${port}/health`);
        console.log(`API docs at http://localhost:${port}/api-docs`);
      });
    }
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

startServer();

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down');
  pool.end().then(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});

module.exports = app;
