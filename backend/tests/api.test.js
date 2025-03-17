/**
 * API Endpoint Tests
 *
 * Tests the basic API endpoints functionality:
 * - Root endpoint response
 * - Not found handling
 * - Request logging
 */

const request = require('supertest');
const pg = require('pg');
const mockClient = pg._mockClient;
const mockPool = pg._mockPool;

describe('API Endpoints', () => {
  let originalEnv;
  let app;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };

    // Set test mode to avoid database connections
    process.env.NODE_ENV = 'test';

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

  it('should return welcome message at root endpoint', async () => {
    // Import the app
    app = require('../index');

    // Make the request
    const response = await request(app).get('/').expect('Content-Type', /json/).expect(200);

    // Check response
    expect(response.body).toHaveProperty('message');
    expect(response.body.message).toContain('Production Experience');
  });

  it('should return 404 for non-existent routes', async () => {
    // Import the app
    app = require('../index');

    // Make the request to a non-existent route
    const response = await request(app)
      .get('/nonexistent-route')
      .expect('Content-Type', /json/)
      .expect(404);

    // Check response
    expect(response.body).toHaveProperty('error');
    expect(response.body.error).toContain('Not Found');
  });

  it('should log requests to the database in production mode', async () => {
    // Set production environment
    process.env.NODE_ENV = 'production';

    // Set up mocks for database interactions
    mockPool.connect
      .mockResolvedValueOnce(mockClient) // For initialization
      .mockResolvedValueOnce(mockClient); // For request logging

    mockClient.query.mockResolvedValue({ rows: [] });

    // Import the app
    app = require('../index');

    // Wait for initialization
    await new Promise(resolve => setTimeout(resolve, 100));

    // Make a request that should be logged
    await request(app).get('/').expect(200);

    // Verify database query was called to log the request
    // Skip metrics endpoint which doesn't log
    expect(mockPool.connect).toHaveBeenCalledTimes(2); // Once for init, once for logging
    expect(mockClient.query).toHaveBeenCalledWith(
      'INSERT INTO metrics(endpoint, method, status_code, duration_ms) VALUES($1, $2, $3, $4)',
      ['/', 'GET', 200, expect.any(Number)]
    );
    expect(mockClient.release).toHaveBeenCalled();
  });

  it('should not log health check requests to database', async () => {
    // Set production environment
    process.env.NODE_ENV = 'production';

    // Set up mocks for database interactions
    mockPool.connect
      .mockResolvedValueOnce(mockClient) // For initialization
      .mockResolvedValueOnce(mockClient); // For health check

    mockClient.query.mockResolvedValue({ rows: [] });

    // Import the app
    app = require('../index');

    // Wait for initialization
    await new Promise(resolve => setTimeout(resolve, 100));

    // Make a request to health endpoint
    await request(app).get('/health').expect(200);

    // Verify the health endpoint request was not logged to DB
    // We should see two connect calls (init and health check) but no INSERT query for logging
    expect(mockPool.connect).toHaveBeenCalledTimes(2);
    expect(mockClient.query).not.toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO metrics'),
      expect.arrayContaining(['/health'])
    );
  });
});
