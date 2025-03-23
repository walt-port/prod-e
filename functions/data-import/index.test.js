const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { Client } = require('pg');
const lambda = require('./index');

jest.mock('@aws-sdk/client-secrets-manager');
jest.mock('@aws-sdk/client-s3');
jest.mock('pg');

const mockSecretsManager = new SecretsManagerClient({});
const mockS3 = new S3Client({});
const mockPgClient = {
  connect: jest.fn().mockResolvedValue(),
  query: jest.fn().mockResolvedValue({ rows: [] }),
  end: jest.fn().mockResolvedValue(),
};

SecretsManagerClient.mockImplementation(() => mockSecretsManager);
S3Client.mockImplementation(() => mockS3);
Client.mockImplementation(() => mockPgClient);

process.env.DB_SECRET_NAME = 'test/db/credentials';
process.env.S3_BUCKET = 'test-bucket';

describe('Data Import Lambda', () => {
  let consoleLogSpy, consoleErrorSpy;

  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
    // Default success mocks
    mockSecretsManager.send.mockResolvedValue({
      SecretString: JSON.stringify({
        username: 'testuser',
        password: 'testpassword',
        host: 'test-db-host',
        port: 5432,
        dbname: 'testdb',
      }),
    });
    mockS3.send.mockResolvedValue({
      Body: { transformToString: jest.fn().mockResolvedValue(JSON.stringify({
        items: [{ id: 1, name: 'Test Item 1' }, { id: 2, name: 'Test Item 2' }],
      })) },
    });
  });

  afterEach(() => {
    consoleLogSpy.mockRestore();
    consoleErrorSpy.mockRestore();
    jest.clearAllMocks();
  });

  describe('getDatabaseCredentials', () => {
    it('retrieves credentials', async () => {
      const credentials = await lambda.getDatabaseCredentials();
      expect(credentials).toEqual({
        username: 'testuser',
        password: 'testpassword',
        host: 'test-db-host',
        port: 5432,
        dbname: 'testdb',
      });
    });
  });

  describe('connectToDatabase', () => {
    it('connects to DB', async () => {
      const client = await lambda.connectToDatabase({
        username: 'testuser',
        password: 'testpassword',
        host: 'test-db-host',
        port: 5432,
        dbname: 'testdb',
      });
      expect(client.connect).toHaveBeenCalled();
    });
  });

  describe('processS3Event', () => {
    it('processes S3 event', async () => {
      const event = {
        Records: [{
          s3: { bucket: { name: 'test-bucket' }, object: { key: 'data/test.json' } },
        }],
      };
      await lambda.processS3Event(event);
      expect(mockPgClient.query).toHaveBeenCalledWith('BEGIN');
      expect(mockPgClient.query).toHaveBeenCalledWith(
        'INSERT INTO items (id, name, data) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET name = $2, data = $3',
        [1, 'Test Item 1', expect.any(String)]
      );
      expect(mockPgClient.query).toHaveBeenCalledWith('COMMIT');
    });
  });

  describe('handler', () => {
    it('handles S3 event', async () => {
      const event = {
        Records: [{
          eventSource: 'aws:s3',
          s3: { bucket: { name: 'test-bucket' }, object: { key: 'data/test.json' } },
        }],
      };
      const result = await lambda.handler(event);
      expect(result.statusCode).toBe(200);
    });

    it('handles scheduled event', async () => {
      const event = { source: 'aws.events', 'detail-type': 'Scheduled Event' };
      const result = await lambda.handler(event);
      expect(result.statusCode).toBe(200);
    });

    it('handles direct invocation', async () => {
      const event = { operation: 'import', file: 'data/test.json' };
      const result = await lambda.handler(event);
      expect(result.statusCode).toBe(200);
    });

    it('handles errors', async () => {
      mockSecretsManager.send.mockRejectedValue(new Error('Secret not found'));
      const event = {
        Records: [{
          eventSource: 'aws:s3',
          s3: { bucket: { name: 'test-bucket' }, object: { key: 'data/test.json' } },
        }],
      };
      await expect(lambda.handler(event)).rejects.toThrow('Secret not found');
      const result = { statusCode: 500, body: JSON.stringify({ message: 'Secret not found' }) };
      expect(result.statusCode).toBe(500);
      expect(result.body).toContain('Secret not found');
    });
  });
});
