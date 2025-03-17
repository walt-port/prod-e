/**
 * Centralized mock for AWS SDK
 * This prevents warnings and provides consistent mocking behavior
 */

// Create mock AWS services
const mockS3 = {
  getObject: jest.fn().mockReturnValue({
    promise: jest.fn().mockResolvedValue({ Body: Buffer.from('mock-data') }),
  }),
  putObject: jest.fn().mockReturnValue({
    promise: jest.fn().mockResolvedValue({}),
  }),
};

const mockSecretsManager = {
  getSecretValue: jest.fn().mockReturnValue({
    promise: jest.fn().mockResolvedValue({
      SecretString: JSON.stringify({
        host: 'test-host',
        port: '5432',
        dbname: 'test-db',
        username: 'test-user',
        password: 'test-password',
      }),
    }),
  }),
};

const mockCloudWatch = {
  putMetricData: jest.fn().mockReturnValue({
    promise: jest.fn().mockResolvedValue({}),
  }),
};

// Create AWS SDK mock with config
const AWS = {
  config: {
    update: jest.fn(),
  },
  S3: jest.fn(() => mockS3),
  SecretsManager: jest.fn(() => mockSecretsManager),
  CloudWatch: jest.fn(() => mockCloudWatch),
};

// Export the mocked AWS SDK
module.exports = AWS;
