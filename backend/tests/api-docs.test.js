/**
 * API Documentation Endpoint Tests
 *
 * Tests the /api-docs endpoint functionality including:
 * - Proper response with Swagger UI
 * - Proper content and references
 */

const request = require('supertest');

// Mock the swagger-jsdoc to control what's returned
jest.mock('swagger-jsdoc', () => {
  return jest.fn(() => ({
    openapi: '3.0.0',
    info: {
      title: 'Production Experience API',
      version: '1.0.0',
      description: 'API for monitoring and metrics collection',
    },
    paths: {
      '/health': {
        get: {
          summary: 'Health endpoint',
        },
      },
      '/metrics': {
        get: {
          summary: 'Metrics endpoint',
        },
      },
    },
  }));
});

describe('API Documentation Endpoint', () => {
  let app;

  beforeAll(() => {
    // Set test environment
    process.env.NODE_ENV = 'test';

    // Import the app
    app = require('../index');
  });

  it('should return 200 and HTML content with Swagger UI', async () => {
    // Make the request
    const response = await request(app)
      .get('/api-docs/')
      .expect('Content-Type', /html/)
      .expect(200);

    // Check for Swagger UI elements in the HTML
    expect(response.text).toMatch(/swagger-ui/i);
  });

  it('should have the Swagger UI JavaScript initialized', async () => {
    const response = await request(app).get('/api-docs/swagger-ui-init.js').expect(200);

    // Check for the Swagger spec definition
    expect(response.text).toMatch(/SwaggerUIBundle/);
  });

  it('should serve the Swagger UI bundle JS', async () => {
    const response = await request(app).get('/api-docs/swagger-ui-bundle.js').expect(200);

    expect(response.headers['content-type']).toMatch(/javascript/i);
  });

  it('should include necessary Swagger UI assets', async () => {
    // Test CSS loading
    await request(app).get('/api-docs/swagger-ui.css').expect(200);

    // Test favicon loading
    await request(app).get('/api-docs/favicon-32x32.png').expect(200);
  });
});
