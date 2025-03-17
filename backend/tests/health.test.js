/**
 * Health Endpoint Tests
 *
 * Tests the /health endpoint functionality including:
 * - Proper response when database is available
 * - Proper error handling when database is unavailable
 * - Test mode behavior
 */

const request = require('supertest');
const pg = require('pg');
const mockClient = pg._mockClient;
const mockPool = pg._mockPool;

describe('Health Endpoint', () => {
  let originalEnv;
  let app;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };

    // Reset mocks
    pg._reset();
  });

  afterEach(() => {
    // Restore original environment
    process.env = { ...originalEnv };

    // Clean up app if it was loaded
    if (app && app.close) {
      app.close();
    }
  });

  it('should return 200 and database status disconnected in test mode', async () => {
    // Set environment to test mode
    process.env.NODE_ENV = 'test';

    // Import the app
    app = require('../index');

    // Make the request
    const response = await request(app).get('/health').expect('Content-Type', /json/).expect(200);

    // Check response in test mode
    expect(response.body).toHaveProperty('status', 'ok');
    expect(response.body).toHaveProperty('database', 'disconnected'); // Disconnected in test mode
    expect(response.body).toHaveProperty('timestamp');

    // In test mode, database connection is skipped
    expect(mockPool.connect).not.toHaveBeenCalled();
  });

  it('should return 200 and status OK when database is connected', async () => {
    // Set environment to production
    process.env.NODE_ENV = 'production';

    // Configure mock responses for both database initialization and health check
    mockPool.connect
      .mockResolvedValueOnce(mockClient) // For initialization
      .mockResolvedValueOnce(mockClient); // For health check

    mockClient.query
      .mockResolvedValueOnce({ rows: [] }) // For database initialization
      .mockResolvedValueOnce({ rows: [] }); // For health check query

    // Import the app
    app = require('../index');

    // Wait for initialization to complete
    await new Promise(resolve => setTimeout(resolve, 100));

    // Make the request
    const response = await request(app).get('/health').expect('Content-Type', /json/).expect(200);

    // Check response when DB is connected
    expect(response.body).toHaveProperty('status', 'ok');
    expect(response.body).toHaveProperty('database', 'connected');
    expect(response.body).toHaveProperty('timestamp');

    // Verify database interactions
    expect(mockPool.connect).toHaveBeenCalledTimes(2); // Once for init, once for health check
    expect(mockClient.query).toHaveBeenCalled();
    expect(mockClient.release).toHaveBeenCalled();
  });

  it('should return 500 when database connection fails', async () => {
    // Set environment to production
    process.env.NODE_ENV = 'production';

    // Configure mocks: First success for initialization, then failure for health check
    mockPool.connect
      .mockResolvedValueOnce(mockClient) // Success for initialization
      .mockRejectedValueOnce(new Error('Connection failed')); // Failure for health check

    mockClient.query.mockResolvedValue({ rows: [] });

    // Import the app
    app = require('../index');

    // Wait for initialization
    await new Promise(resolve => setTimeout(resolve, 100));

    // Make the request, expecting a 500 status
    const response = await request(app).get('/health').expect('Content-Type', /json/).expect(500);

    // Check error response
    expect(response.body).toHaveProperty('status', 'error');
    expect(response.body).toHaveProperty('database', 'disconnected');
    expect(response.body).toHaveProperty('message', 'Database connection failed');
    expect(response.body).toHaveProperty('timestamp');
  });
});
