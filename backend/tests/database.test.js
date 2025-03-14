/**
 * Database Connection Tests
 *
 * Tests the database connection functionality:
 * - Validates connection parameters
 * - Tests connection error handling
 * - Verifies database initialization
 */

// Create mock objects
const mockClient = {
  query: jest.fn().mockResolvedValue({}),
  release: jest.fn(),
};

const mockPool = {
  connect: jest.fn().mockResolvedValue(mockClient),
  on: jest.fn(),
};

// Mock the pg module
jest.mock('pg', () => {
  return {
    Pool: jest.fn(() => mockPool),
  };
});

describe('Database Connection', () => {
  let originalEnv;
  let Pool;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };

    // Clear module cache to ensure fresh app instance
    jest.resetModules();

    // Reset mocks
    jest.clearAllMocks();

    // Set test environment variables
    process.env.NODE_ENV = 'development';
    process.env.DB_HOST = 'test-host';
    process.env.DB_PORT = '5432';
    process.env.DB_NAME = 'test-db';
    process.env.DB_USER = 'test-user';
    process.env.DB_PASSWORD = 'test-password';

    // Get the mocked Pool constructor
    Pool = require('pg').Pool;
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
  });

  it('should not connect to database in test mode', async () => {
    // Set test environment
    process.env.NODE_ENV = 'test';

    // Mock console.log to avoid cluttering test output
    jest.spyOn(console, 'log').mockImplementation(() => {});

    // Import the app
    const app = require('../index');

    // Check that Pool was not called
    expect(Pool).not.toHaveBeenCalled();
  });

  it('should initialize database with correct configuration', async () => {
    // Mock console.log to avoid cluttering test output
    jest.spyOn(console, 'log').mockImplementation(() => {});

    // Import the app
    const app = require('../index');

    // Check that Pool was constructed
    expect(Pool).toHaveBeenCalledTimes(1);

    // Check the configuration passed to Pool
    const poolConfig = Pool.mock.calls[0][0];
    expect(poolConfig).toEqual({
      host: 'test-host',
      port: '5432',
      database: 'test-db',
      user: 'test-user',
      password: 'test-password',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    // Wait for any promises to resolve
    await new Promise(resolve => setTimeout(resolve, 100));

    // Check that connect was called (for database initialization)
    expect(mockPool.connect).toHaveBeenCalled();

    // Check that query was called on the client
    expect(mockClient.query).toHaveBeenCalled();
    expect(mockClient.query).toHaveBeenCalledWith(
      expect.stringContaining('CREATE TABLE IF NOT EXISTS metrics')
    );

    // Check that client was released
    expect(mockClient.release).toHaveBeenCalled();
  });

  it('should handle database connection errors gracefully', async () => {
    // Mock console.error to avoid cluttering test output
    jest.spyOn(console, 'error').mockImplementation(() => {});

    // Make the connect method throw an error
    mockPool.connect.mockRejectedValueOnce(new Error('Connection error'));

    // Import the app
    const app = require('../index');

    // Wait for any promises to resolve
    await new Promise(resolve => setTimeout(resolve, 100));

    // Check that console.error was called with the error
    expect(console.error).toHaveBeenCalledWith(
      'Error initializing database:',
      expect.objectContaining({ message: 'Connection error' })
    );
  });
});
