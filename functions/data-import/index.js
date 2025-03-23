const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { Client } = require('pg');

const secretsManager = new SecretsManagerClient({ region: process.env.AWS_REGION || 'us-west-2' });
const s3 = new S3Client({ region: process.env.AWS_REGION || 'us-west-2' });

async function getDatabaseCredentials() {
  const secretName = process.env.DB_SECRET_NAME || 'prod-e-db-credentials';
  console.log(`Fetching DB credentials from ${secretName}`);
  try {
    const { SecretString } = await secretsManager.send(new GetSecretValueCommand({ SecretId: secretName }));
    return JSON.parse(SecretString);
  } catch (error) {
    console.error(`Error fetching DB credentials: ${error.message}`);
    throw error;
  }
}

async function connectToDatabase(credentials) {
  console.log(`Connecting to DB at ${credentials.host}`);
  const client = new Client({
    user: credentials.username,
    password: credentials.password,
    host: credentials.host,
    port: credentials.port,
    database: credentials.dbname,
  });
  await client.connect();
  console.log('DB connected');
  return client;
}

async function processS3Event(event) {
  if (!event.Records || !event.Records[0]?.s3) {
    console.log('No valid S3 records');
    return;
  }
  const { bucket: { name: bucket }, object: { key } } = event.Records[0].s3;
  console.log(`Processing s3://${bucket}/${key}`);

  let client;
  try {
    const credentials = await getDatabaseCredentials();
    client = await connectToDatabase(credentials);
    const { Body } = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
    const data = JSON.parse(await Body.transformToString());
    console.log(`Parsed ${data.items?.length || 0} items`);

    await client.query('BEGIN');
    if (data.items && Array.isArray(data.items)) {
      for (const item of data.items) {
        await client.query(
          'INSERT INTO items (id, name, data) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET name = $2, data = $3',
          [item.id, item.name, JSON.stringify(item)]
        );
      }
      console.log(`Imported ${data.items.length} items`);
    }
    await client.query('COMMIT');
  } catch (error) {
    console.error(`Error processing S3: ${error.message}`);
    if (client) await client.query('ROLLBACK');
    throw error; // Ensure error propagates
  } finally {
    if (client) await client.end();
  }
}

async function handler(event) {
  console.log('Event:', JSON.stringify(event));
  try {
    if (event.Records?.[0]?.eventSource === 'aws:s3') {
      await processS3Event(event);
    } else if (event.source === 'aws.events' && event['detail-type'] === 'Scheduled Event') {
      console.log('Scheduled event - add logic here');
    } else if (event.operation === 'import' && event.file) {
      await processS3Event({
        Records: [{ s3: { bucket: { name: process.env.S3_BUCKET || 'prod-e-data' }, object: { key: event.file } } }]
      });
    } else {
      throw new Error('Invalid event');
    }
    return { statusCode: 200, body: JSON.stringify({ message: 'Success' }) };
  } catch (error) {
    console.error(`Handler error: ${error.message}`);
    throw error; // Throw to ensure 500 status in Lambda runtime
  }
}

module.exports = { handler, getDatabaseCredentials, connectToDatabase, processS3Event };
