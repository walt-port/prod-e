/**
 * Database Connection Tests
 *
 * Tests the database connection functionality:
 * - Validates connection parameters
 * - Tests connection error handling
 * - Verifies database initialization
 */

// Import and set up the pg mock from the centralized location
const pg = require('pg');
const mockClient = pg._mockClient;
const mockPool = pg._mockPool;
const Pool = pg.Pool;

describe('Database Connection', () => {
  let originalEnv;

  beforeEach(() => {
    // Save original environment and set test values
    originalEnv = { ...process.env };

    // Set test environment variables
    process.env.NODE_ENV = 'production';
    process.env.DB_HOST = 'test-host';
    process.env.DB_PORT = '5432';
    process.env.DB_NAME = 'test-db';
    process.env.DB_USER = 'test-user';
    process.env.DB_PASSWORD = 'test-password';

    // Reset pg module mocks
    pg._reset();
  });

  afterEach(() => {
    // Restore original environment
    process.env = { ...originalEnv };
  });

  it('should initialize database with correct configuration', async () => {
    // Set up the successful connection path
    mockPool.connect.mockResolvedValue(mockClient);
    mockClient.query.mockResolvedValue({ rows: [] });

    // Import the app
    require('../index');

    // Wait for any promises to resolve
    await new Promise(resolve => setTimeout(resolve, 100));

    // Check that Pool was constructed
    expect(Pool).toHaveBeenCalled();

    // Check the configuration passed to Pool
    const poolConfig = mockPool.config;
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

    // Check that connect was called (for database initialization)
    expect(mockPool.connect).toHaveBeenCalled();

    // Check that query was called on the client to create the table
    expect(mockClient.query).toHaveBeenCalledWith(
      expect.stringContaining('CREATE TABLE IF NOT EXISTS metrics')
    );

    // Check that client was released
    expect(mockClient.release).toHaveBeenCalled();
  });

  it('should handle database connection errors gracefully', async () => {
    // Make the connect method throw an error for this test
    const connectionError = new Error('Connection error');
    mockPool.connect.mockRejectedValueOnce(connectionError);

    // Spy on console.error
    jest.spyOn(console, 'error').mockImplementation(() => {});

    // Import the app
    require('../index');

    // Wait for any promises to resolve (including the rejected one)
    await new Promise(resolve => setTimeout(resolve, 100));

    // Check that console.error was called with the error
    expect(console.error).toHaveBeenCalledWith('Error initializing database:', connectionError);
  });

  it('should skip database connection in test environment', async () => {
    // Set environment to test
    process.env.NODE_ENV = 'test';

    // Import the app
    require('../index');

    // Wait a moment
    await new Promise(resolve => setTimeout(resolve, 50));

    // Check that Pool was not constructed in test environment
    expect(Pool).not.toHaveBeenCalled();

    // Check that connect was not called
    expect(mockPool.connect).not.toHaveBeenCalled();
  });
});
