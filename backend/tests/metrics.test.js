/**
 * Metrics Endpoint Tests
 *
 * Tests the Prometheus metrics endpoint functionality:
 * - Proper response format
 * - Error handling
 */

const request = require('supertest');

// Mock prom-client
jest.mock('prom-client', () => {
  const mockRegistry = {
    metrics: jest.fn().mockResolvedValue('mock metrics data'),
    contentType: 'text/plain; version=0.0.4; charset=utf-8',
  };

  return {
    Counter: jest.fn().mockImplementation(() => ({
      inc: jest.fn(),
      labels: jest.fn().mockReturnThis(),
    })),
    Histogram: jest.fn().mockImplementation(() => ({
      observe: jest.fn(),
      labels: jest.fn().mockReturnThis(),
    })),
    Registry: jest.fn(() => mockRegistry),
    collectDefaultMetrics: jest.fn(),
  };
});

// Mock metrics generation error scenario separately
jest.mock(
  '../utils/metrics-generator',
  () => {
    return {
      generateMetrics: jest.fn().mockImplementation(() => {
        throw new Error('Metrics generation failed');
      }),
    };
  },
  { virtual: true }
);

describe('Metrics Endpoint', () => {
  let originalEnv;
  let app;
  let promClient;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };

    // Set test environment
    process.env.NODE_ENV = 'test';

    // Get access to the mock registry
    promClient = require('prom-client');
  });

  afterEach(() => {
    // Restore original environment
    process.env = { ...originalEnv };

    // Clean up app if it was loaded
    if (app && app.close) {
      app.close();
    }
  });

  it('should return metrics data with correct content type', async () => {
    // Import the app
    app = require('../index');

    // Make the request
    const response = await request(app)
      .get('/metrics')
      .expect('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
      .expect(200);

    // Check response
    expect(response.text).toBe('mock metrics data');
    expect(promClient.Registry().metrics).toHaveBeenCalled();
  });

  it('should handle errors during metrics generation', async () => {
    // Reset modules to ensure our mock error is used
    jest.resetModules();

    // Create error in metrics generation
    promClient.Registry().metrics.mockRejectedValueOnce(new Error('Metrics generation failed'));

    // Import the app
    app = require('../index');

    // Make request that should trigger an error
    const response = await request(app).get('/metrics').expect(500);

    // Check error response
    expect(response.text).toBe('Error generating metrics');
  });

  it('should register custom metrics with the registry', async () => {
    // Import the app
    app = require('../index');

    // Verify metrics were registered
    expect(promClient.Counter).toHaveBeenCalledWith(
      expect.objectContaining({
        name: 'http_requests_total',
        help: expect.any(String),
      })
    );

    expect(promClient.Histogram).toHaveBeenCalledWith(
      expect.objectContaining({
        name: 'http_request_duration_seconds',
        help: expect.any(String),
      })
    );
  });
});
