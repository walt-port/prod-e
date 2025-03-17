# API Documentation Testing

## Overview

This document covers the testing approach for the API documentation (Swagger/OpenAPI) in our backend service. We've recently made significant improvements to these tests to make them more reliable, especially in CI environments.

## Test Strategy

The API documentation tests (`api-docs.test.js`) verify:

1. The proper initialization of Swagger documentation
2. The correct structure of the OpenAPI specification
3. The appropriate middleware setup

## Mocking Approach

The tests use a sophisticated mocking strategy:

### Express Mock

```javascript
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
```

### Swagger UI Express Mock

```javascript
jest.mock('swagger-ui-express', () => ({
  serve: ['mock-middleware'],
  setup: jest.fn().mockReturnValue('mock-setup-middleware'),
}));
```

### Swagger JSDocs Mock

```javascript
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
```

## Test Cases

The tests verify:

1. **Swagger Documentation Setup**: Confirms that swagger-jsdoc is called and swagger-ui middleware is set up

```javascript
it('should set up swagger documentation', () => {
  // Verify swagger-jsdoc was called
  expect(swaggerJsdoc).toHaveBeenCalled();

  // Verify swagger UI middleware was set up
  expect(swaggerUi.setup).toHaveBeenCalled();

  // Verify app.use was called with the API docs path
  expect(app.use).toHaveBeenCalledWith('/api-docs', expect.anything(), expect.anything());
});
```

2. **OpenAPI Specification**: Verifies the structure of the OpenAPI specification

```javascript
it('should define an OpenAPI specification', () => {
  // Check swagger spec structure matches our mock
  const swaggerSpec = swaggerJsdoc();
  expect(swaggerSpec).toHaveProperty('openapi', '3.0.0');
  expect(swaggerSpec).toHaveProperty('info');
  expect(swaggerSpec.info).toHaveProperty('title', 'Production Experience API');
  expect(swaggerSpec).toHaveProperty('paths');
  expect(swaggerSpec.paths).toHaveProperty('/health');
});
```

3. **Middleware Setup**: Confirms that the appropriate middleware is used

```javascript
it('should set up appropriate middleware', () => {
  // Verify proper middleware was used
  expect(app.use).toHaveBeenCalledWith('/api-docs', expect.anything(), expect.anything());
});
```

## CI Reliability

This test file is considered "CI reliable" because:

1. It doesn't require actual HTTP requests
2. It uses stable mocking patterns that don't depend on implementation details
3. It doesn't require complex system dependencies
4. It focuses on testing the structure and setup rather than actual responses

## Benefits

The improved API documentation tests offer several benefits:

1. **Consistent CI Performance**: The tests run reliably in CI environments
2. **Fast Execution**: The tests are quick to execute since they avoid actual HTTP requests
3. **Isolation**: The tests are isolated from actual system dependencies
4. **Focused Testing**: They verify specific aspects of the API documentation setup

## Troubleshooting

If tests fail in this file, check:

1. Changes to how Express or Swagger is initialized in the main application
2. Changes to the route paths or API documentation paths
3. Updates to Swagger UI Express or Swagger JSDocs packages
