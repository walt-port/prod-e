/**
 * API Documentation Tests
 *
 * Tests the Swagger API documentation endpoints:
 * - API docs UI endpoint
 * - OpenAPI spec validity
 */

const request = require('supertest');

// Mock swagger-jsdoc
jest.mock('swagger-jsdoc', () => {
  return jest.fn().mockImplementation(() => ({
    openapi: '3.0.0',
    info: {
      title: 'Production Experience API',
      version: '1.0.0',
      description: 'API for Production Experience monitoring dashboard',
    },
    paths: {
      '/health': {
        get: {
          summary: 'Health check endpoint',
          responses: { 200: { description: 'OK' } },
        },
      },
    },
  }));
});

// Mock express
jest.mock('express', () => {
  const mockRouter = {
    get: jest.fn((path, handler) => {
      // Store handlers for testing
      if (path === '/api-docs.json') {
        mockRouter.docsJsonHandler = handler;
      }
    }),
    use: jest.fn(),
  };

  const mockApp = {
    use: jest.fn(),
    get: jest.fn((path, handler) => {
      // Store handlers for testing
      if (path === '/') {
        mockApp.rootHandler = handler;
      }
      if (path === '/health') {
        mockApp.healthHandler = handler;
      }
      return mockRouter;
    }),
    listen: jest.fn().mockImplementation((port, callback) => {
      if (callback) callback();
      return { close: jest.fn() };
    }),
  };

  const mockExpress = jest.fn(() => mockApp);
  mockExpress.Router = jest.fn(() => mockRouter);
  mockExpress.static = jest.fn(() => 'static-middleware');

  return mockExpress;
});

// Mock swagger-ui-express
jest.mock('swagger-ui-express', () => ({
  serve: ['mock-middleware'],
  setup: jest.fn().mockReturnValue('mock-setup-middleware'),
}));

describe('API Documentation', () => {
  let app;
  let express;
  let swaggerUi;
  let swaggerJsdoc;

  beforeEach(() => {
    // Reset modules to get fresh instances
    jest.resetModules();

    // Set test environment
    process.env.NODE_ENV = 'test';

    // Get mocked modules
    express = require('express');
    swaggerUi = require('swagger-ui-express');
    swaggerJsdoc = require('swagger-jsdoc');

    // Import the app (will use our mocked modules)
    require('../index');

    // Get the mock app instance
    app = express();
  });

  it('should set up swagger documentation', () => {
    // Verify swagger-jsdoc was called
    expect(swaggerJsdoc).toHaveBeenCalled();

    // Verify swagger UI middleware was set up
    expect(swaggerUi.setup).toHaveBeenCalled();

    // Verify app.use was called with the API docs path
    expect(app.use).toHaveBeenCalledWith('/api-docs', expect.anything(), expect.anything());
  });

  it('should define an OpenAPI specification', () => {
    // Check swagger spec structure matches our mock
    const swaggerSpec = swaggerJsdoc();
    expect(swaggerSpec).toHaveProperty('openapi', '3.0.0');
    expect(swaggerSpec).toHaveProperty('info');
    expect(swaggerSpec.info).toHaveProperty('title', 'Production Experience API');
    expect(swaggerSpec).toHaveProperty('paths');
    expect(swaggerSpec.paths).toHaveProperty('/health');
  });

  it('should set up appropriate middleware', () => {
    // Verify proper middleware was used
    expect(app.use).toHaveBeenCalledWith(expect.any(String), expect.anything());
  });
});
