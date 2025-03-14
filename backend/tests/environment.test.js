/**
 * Environment Variable Tests
 *
 * Tests the application's handling of environment variables:
 * - Default values for missing environment variables
 * - Processing of database configuration
 * - Handling of different environments (dev, test, prod)
 */

// Mock express before requiring any modules
jest.mock('express', () => {
  const mockListen = jest.fn();
  const mockUse = jest.fn();
  const mockGet = jest.fn();
  const mockStatic = jest.fn(() => 'static-middleware');

  const mockExpress = jest.fn(() => ({
    use: mockUse,
    get: mockGet,
    listen: mockListen,
  }));

  mockExpress.static = mockStatic;
  return mockExpress;
});

// Mock swagger-ui-express
jest.mock('swagger-ui-express', () => ({
  serve: ['swagger-ui-middleware'],
  setup: jest.fn(() => 'swagger-ui-setup'),
}));

// Mock swagger-jsdoc
jest.mock('swagger-jsdoc', () => {
  return jest.fn(() => ({ openapi: '3.0.0' }));
});

// Mock pg
jest.mock('pg', () => {
  const mockClient = {
    query: jest.fn().mockResolvedValue({ rows: [] }),
    release: jest.fn(),
  };

  const mockPool = {
    connect: jest.fn().mockResolvedValue(mockClient),
    end: jest.fn().mockResolvedValue(undefined),
  };

  return {
    Pool: jest.fn(config => {
      mockPool.config = config;
      return mockPool;
    }),
  };
});

// Mock prom-client
jest.mock('prom-client', () => {
  const mockCollectDefaultMetrics = jest.fn();
  const mockRegisterMetric = jest.fn();
  const mockRegistry = {
    registerMetric: mockRegisterMetric,
    contentType: 'text/plain',
    metrics: jest.fn().mockResolvedValue('metrics data'),
  };

  return {
    Registry: jest.fn(() => mockRegistry),
    collectDefaultMetrics: mockCollectDefaultMetrics,
    Histogram: jest.fn(),
    Counter: jest.fn(),
  };
});

describe('Environment Variable Handling', () => {
  let promClient;
  let pg;
  let originalEnv;
  let originalModule;

  beforeEach(() => {
    // Save original environment
    originalEnv = process.env;
    originalModule = require.main;

    // Start with a clean environment
    process.env = {};

    // Clear cache to ensure fresh app instance
    jest.resetModules();

    // Reset mocks
    promClient = require('prom-client');
    pg = require('pg');
  });

  afterEach(() => {
    // Restore original environment and module
    process.env = originalEnv;
    require.main = originalModule;
  });

  it('should use custom metrics prefix when METRICS_PREFIX is set', () => {
    // Set custom metrics prefix
    process.env.METRICS_PREFIX = 'custom_prefix_';
    process.env.NODE_ENV = 'test'; // Avoid DB connection

    // Import the app
    require('../index');

    // Check if metrics prefix was used
    expect(promClient.collectDefaultMetrics).toHaveBeenCalledWith(
      expect.objectContaining({
        prefix: 'custom_prefix_',
      })
    );
  });

  it('should not connect to database in test mode', () => {
    // Set environment to test
    process.env.NODE_ENV = 'test';

    // Import the app
    require('../index');

    // Check that database connection was not instantiated
    expect(pg.Pool).not.toHaveBeenCalled();
  });

  it('should use database configuration from environment variables', () => {
    // Set environment to production with DB config
    process.env.NODE_ENV = 'production';
    process.env.DB_HOST = 'testhost';
    process.env.DB_PORT = '5432';
    process.env.DB_NAME = 'testdb';
    process.env.DB_USER = 'testuser';
    process.env.DB_PASSWORD = 'testpass';

    // Import the app
    require('../index');

    // Get the Pool instance
    const poolInstance = pg.Pool.mock.calls[0][0];

    // Check database configuration
    expect(poolInstance).toEqual({
      host: 'testhost',
      port: '5432',
      database: 'testdb',
      user: 'testuser',
      password: 'testpass',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
  });
});
