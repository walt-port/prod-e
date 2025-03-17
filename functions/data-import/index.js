/**
 * Lambda function to import data into RDS database
 * This function can be triggered by S3 events or scheduled via EventBridge
 */

const AWS = require('aws-sdk');
const { Client } = require('pg');

// Initialize AWS SDK
const secretsManager = new AWS.SecretsManager();
const s3 = new AWS.S3();

/**
 * Retrieves database credentials from AWS Secrets Manager
 * @returns {Promise<Object>} Database credentials
 */
async function getDatabaseCredentials() {
  const secretName = process.env.DB_SECRET_NAME || 'prod-e/db/credentials';
  console.log(`Retrieving database credentials from secret: ${secretName}`);

  try {
    const secretData = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
    if (!secretData.SecretString) {
      throw new Error('Secret does not contain a SecretString');
    }

    const credentials = JSON.parse(secretData.SecretString);
    console.log('Successfully retrieved database credentials');
    return credentials;
  } catch (error) {
    console.error(`Error retrieving database credentials: ${error.message}`);
    throw error;
  }
}

/**
 * Connects to the PostgreSQL database
 * @param {Object} credentials - Database credentials
 * @returns {Promise<Client>} PostgreSQL client
 */
async function connectToDatabase(credentials) {
  console.log(`Connecting to database at ${credentials.host}`);

  const client = new Client({
    user: credentials.username,
    password: credentials.password,
    host: credentials.host,
    port: credentials.port,
    database: credentials.dbname
  });

  try {
    await client.connect();
    console.log('Successfully connected to database');
    return client;
  } catch (error) {
    console.error(`Error connecting to database: ${error.message}`);
    throw error;
  }
}

/**
 * Processes an S3 event
 * @param {Object} event - S3 event
 * @returns {Promise<void>}
 */
async function processS3Event(event) {
  if (!event.Records || event.Records.length === 0) {
    console.log('No records found in event');
    return;
  }

  const bucket = event.Records[0].s3.bucket.name;
  const key = event.Records[0].s3.object.key;
  console.log(`Processing S3 event for: s3://${bucket}/${key}`);

  let client;
  try {
    // Get database credentials
    const credentials = await getDatabaseCredentials();

    // Connect to database
    client = await connectToDatabase(credentials);

    // Get file from S3
    const fileData = await s3.getObject({
      Bucket: bucket,
      Key: key
    }).promise();

    // Parse data
    const data = JSON.parse(fileData.Body.toString('utf-8'));
    console.log(`Successfully parsed data from S3: ${JSON.stringify(data).substring(0, 100)}...`);

    // Begin transaction
    await client.query('BEGIN');

    // Import data into database
    if (data.items && Array.isArray(data.items)) {
      console.log(`Importing ${data.items.length} items`);

      for (const item of data.items) {
        // Insert item into database
        await client.query(
          'INSERT INTO items (id, name, data) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET name = $2, data = $3',
          [item.id, item.name, JSON.stringify(item)]
        );
      }

      console.log(`Successfully imported ${data.items.length} items`);
    } else {
      console.log('No items found in data');
    }

    // Commit transaction
    await client.query('COMMIT');
    console.log('Transaction committed successfully');
  } catch (error) {
    console.error(`Error processing S3 event: ${error.message}`);

    // Rollback transaction if client exists
    if (client) {
      try {
        await client.query('ROLLBACK');
        console.log('Transaction rolled back due to error');
      } catch (rollbackError) {
        console.error(`Error rolling back transaction: ${rollbackError.message}`);
      }
    }

    throw error;
  } finally {
    // Close database connection
    if (client) {
      await client.end();
      console.log('Database connection closed');
    }
  }
}

/**
 * Lambda handler function
 * @param {Object} event - Lambda event
 * @param {Object} context - Lambda context
 * @returns {Promise<Object>} Lambda response
 */
async function handler(event, context) {
  console.log('Event received:', JSON.stringify(event));

  try {
    // Determine event source and process accordingly
    if (event.Records && event.Records[0].eventSource === 'aws:s3') {
      // S3 event
      await processS3Event(event);
    } else if (event.source === 'aws.events' && event['detail-type'] === 'Scheduled Event') {
      // Scheduled event
      console.log('Processing scheduled event');
      // Add scheduled event processing logic here
    } else {
      // Direct invocation
      console.log('Processing direct invocation');

      if (event.operation === 'import' && event.file) {
        const bucket = process.env.S3_BUCKET || 'prod-e-data';
        await processS3Event({
          Records: [
            {
              s3: {
                bucket: { name: bucket },
                object: { key: event.file }
              }
            }
          ]
        });
      } else {
        throw new Error('Invalid operation or missing parameters');
      }
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Successfully processed event' })
    };
  } catch (error) {
    console.error(`Error processing event: ${error.message}`);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: `Error: ${error.message}` })
    };
  }
}

// Export handler as well as other functions for testing
module.exports = {
  handler,
  getDatabaseCredentials,
  connectToDatabase,
  processS3Event
};
