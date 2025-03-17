const AWS = require('aws-sdk');
const { Client } = require('pg');
const lambda = require('./index');

// Mocks
jest.mock('aws-sdk', () => {
  const mockSecretsManager = {
    getSecretValue: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        SecretString: JSON.stringify({
          username: 'testuser',
          password: 'testpassword',
          host: 'test-db-host',
          port: 5432,
          dbname: 'testdb',
        }),
      }),
    }),
  };

  const mockS3 = {
    getObject: jest.fn().mockReturnValue({
      promise: jest.fn().mockResolvedValue({
        Body: Buffer.from(
          JSON.stringify({
            items: [
              { id: 1, name: 'Test Item 1' },
              { id: 2, name: 'Test Item 2' },
            ],
          })
        ),
      }),
    }),
  };

  return {
    SecretsManager: jest.fn(() => mockSecretsManager),
    S3: jest.fn(() => mockS3),
  };
});

jest.mock('pg', () => {
  const mockClient = {
    connect: jest.fn().mockResolvedValue(undefined),
    query: jest.fn().mockResolvedValue({ rows: [] }),
    end: jest.fn().mockResolvedValue(undefined),
  };
  return { Client: jest.fn(() => mockClient) };
});

// Test environment setup
process.env.DB_SECRET_NAME = 'test/db/credentials';
process.env.S3_BUCKET = 'test-bucket';

describe('Data Import Lambda', () => {
  let consoleLogSpy;
  let consoleErrorSpy;

  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
  });

  afterEach(() => {
    consoleLogSpy.mockRestore();
    consoleErrorSpy.mockRestore();
    jest.clearAllMocks();
  });

  describe('getDatabaseCredentials', () => {
    it('successfully retrieves credentials from Secrets Manager', async () => {
      const credentials = await lambda.getDatabaseCredentials();

      expect(credentials).toEqual({
        username: 'testuser',
        password: 'testpassword',
        host: 'test-db-host',
        port: 5432,
        dbname: 'testdb',
      });

      const secretsManager = new AWS.SecretsManager();
      expect(secretsManager.getSecretValue).toHaveBeenCalledWith({
        SecretId: 'test/db/credentials',
      });
    });
  });

  describe('connectToDatabase', () => {
    it('successfully connects to the database', async () => {
      const client = await lambda.connectToDatabase({
        username: 'testuser',
        password: 'testpassword',
        host: 'test-db-host',
        port: 5432,
        dbname: 'testdb',
      });

      expect(client).toBeDefined();
      expect(Client).toHaveBeenCalledWith({
        user: 'testuser',
        password: 'testpassword',
        host: 'test-db-host',
        port: 5432,
        database: 'testdb',
      });
      expect(client.connect).toHaveBeenCalled();
    });
  });

  describe('processS3Event', () => {
    it('successfully processes an S3 event', async () => {
      const event = {
        Records: [
          {
            s3: {
              bucket: { name: 'test-bucket' },
              object: { key: 'data/test-file.json' },
            },
          },
        ],
      };

      await lambda.processS3Event(event);

      const s3 = new AWS.S3();
      expect(s3.getObject).toHaveBeenCalledWith({
        Bucket: 'test-bucket',
        Key: 'data/test-file.json',
      });

      // Verify database operations were attempted
      const pgClient = new Client();
      expect(pgClient.query).toHaveBeenCalled();
    });
  });

  describe('handler', () => {
    it('processes an S3 event', async () => {
      const event = {
        Records: [
          {
            eventSource: 'aws:s3',
            s3: {
              bucket: { name: 'test-bucket' },
              object: { key: 'data/test-file.json' },
            },
          },
        ],
      };

      const result = await lambda.handler(event);
      expect(result.statusCode).toBe(200);
    });

    it('handles scheduled events', async () => {
      const event = {
        source: 'aws.events',
        'detail-type': 'Scheduled Event',
      };

      const result = await lambda.handler(event);
      expect(result.statusCode).toBe(200);
    });

    it('handles direct invocations', async () => {
      const event = {
        operation: 'import',
        file: 'data/test-file.json',
      };

      const result = await lambda.handler(event);
      expect(result.statusCode).toBe(200);
    });

    it('handles errors gracefully', async () => {
      // Force an error by setting credentials to undefined
      const secretsManager = new AWS.SecretsManager();
      secretsManager.getSecretValue.mockReturnValue({
        promise: jest.fn().mockRejectedValue(new Error('Secret not found')),
      });

      const event = {
        Records: [
          {
            eventSource: 'aws:s3',
            s3: {
              bucket: { name: 'test-bucket' },
              object: { key: 'data/test-file.json' },
            },
          },
        ],
      };

      const result = await lambda.handler(event);
      expect(result.statusCode).toBe(500);
      expect(result.body).toContain('Error');
    });
  });
});
