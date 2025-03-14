/**
 * Health Endpoint Tests
 *
 * Tests the /health endpoint functionality including:
 * - Proper response when database is available
 * - Proper error handling when database is unavailable
 * - Test mode behavior
 */

const request = require('supertest');

// Create mock client and pool outside the mock definition
// so we can access them in tests
const mockClient = {
  query: jest.fn().mockResolvedValue({ rows: [] }),
  release: jest.fn(),
};

const mockPool = {
  connect: jest.fn().mockResolvedValue(mockClient),
  end: jest.fn().mockResolvedValue(undefined),
};

// Mock the pg Pool
jest.mock('pg', () => {
  return {
    Pool: jest.fn(() => mockPool),
  };
});

describe('Health Endpoint', () => {
  let app;
  let originalEnv;

  beforeEach(() => {
    // Save original environment and clean cache to ensure fresh app instance
    originalEnv = process.env;
    process.env = { ...originalEnv };
    jest.resetModules();

    // Reset mock states
    mockClient.query.mockClear();
    mockClient.release.mockClear();
    mockPool.connect.mockClear();
    mockPool.end.mockClear();

    // Reset default behavior
    mockPool.connect.mockResolvedValue(mockClient);
    mockClient.query.mockResolvedValue({ rows: [] });
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
  });

  it('should return 200 and status OK when database is connected', async () => {
    // Set environment to production
    process.env.NODE_ENV = 'production';

    // Import the app
    app = require('../index');

    // Make the request
    const response = await request(app).get('/health').expect('Content-Type', /json/).expect(200);

    // Check response
    expect(response.body).toHaveProperty('status', 'ok');
    expect(response.body).toHaveProperty('database', 'connected');
    expect(response.body).toHaveProperty('timestamp');

    // Verify database interactions
    expect(mockPool.connect).toHaveBeenCalled();
    expect(mockClient.query).toHaveBeenCalled();
    expect(mockClient.release).toHaveBeenCalled();
  });

  it('should return 500 when database connection fails', async () => {
    // Set environment to production
    process.env.NODE_ENV = 'production';

    // Mock a database connection error for the health endpoint
    // First call is for initialization, second is for health check
    mockPool.connect
      .mockResolvedValueOnce(mockClient) // For initialization
      .mockRejectedValueOnce(new Error('Connection failed')); // For health check

    // Import the app
    app = require('../index');

    // Make the request
    const response = await request(app).get('/health').expect('Content-Type', /json/).expect(500);

    // Check response
    expect(response.body).toHaveProperty('status', 'error');
    expect(response.body).toHaveProperty('message', 'Database connection failed');
    expect(response.body).toHaveProperty('database', 'disconnected');
  });

  it('should skip database check in test mode', async () => {
    // Set environment to test
    process.env.NODE_ENV = 'test';

    // Import the app
    app = require('../index');

    // Make the request
    const response = await request(app).get('/health').expect('Content-Type', /json/).expect(200);

    // Check response
    expect(response.body).toHaveProperty('status', 'ok');
    expect(response.body).toHaveProperty('database', 'skipped (test mode)');

    // Verify no database interactions
    expect(mockPool.connect).not.toHaveBeenCalled();
  });
});
