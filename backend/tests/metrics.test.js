/**
 * Metrics Endpoint Tests
 *
 * Tests the /metrics endpoint functionality including:
 * - Proper response format
 * - Handling of default metrics
 * - Error handling
 */

const request = require('supertest');

describe('Metrics Endpoint', () => {
  let app;
  let originalEnv;

  beforeEach(() => {
    // Save original environment and clean cache to ensure fresh app instance
    originalEnv = process.env;
    process.env = { ...originalEnv };
    process.env.NODE_ENV = 'test'; // Use test mode to avoid database connections

    jest.resetModules();

    // Import the app
    app = require('../index');
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
  });

  it('should return 200 and Prometheus metrics in the correct format', async () => {
    // Make the request
    const response = await request(app).get('/metrics').expect(200);

    // Check content type
    expect(response.headers['content-type']).toMatch(/text\/plain/);

    // Check for common Prometheus metric patterns
    expect(response.text).toMatch(/^# HELP /m); // Help line
    expect(response.text).toMatch(/^# TYPE /m); // Type line

    // Check for our custom metrics
    expect(response.text).toMatch(/http_request_duration_seconds/);
    expect(response.text).toMatch(/http_requests_total/);
  });

  it('should include default metrics with the configured prefix', async () => {
    // Set custom metrics prefix
    process.env.METRICS_PREFIX = 'test_prefix_';
    jest.resetModules();

    // Import the app with new config
    app = require('../index');

    // Make the request
    const response = await request(app).get('/metrics').expect(200);

    // Check for metrics with our prefix
    expect(response.text).toMatch(/test_prefix_/);
  });

  it('should handle errors when generating metrics', async () => {
    jest.resetModules();

    // Mock prom-client to simulate an error
    jest.mock('prom-client', () => {
      const mockRegistry = {
        contentType: 'text/plain',
        metrics: jest.fn().mockRejectedValue(new Error('Metrics generation failed')),
        registerMetric: jest.fn(),
      };

      return {
        Registry: jest.fn(() => mockRegistry),
        collectDefaultMetrics: jest.fn(),
        Histogram: jest.fn(() => ({ name: 'http_request_duration_seconds' })),
        Counter: jest.fn(() => ({ name: 'http_requests_total' })),
      };
    });

    // Import the app with mocked modules
    app = require('../index');

    // Make the request
    const response = await request(app).get('/metrics').expect(500);

    // Check error message
    expect(response.text).toBe('Error generating metrics');
  });
});
