# Testing Documentation

## Overview

This document provides comprehensive information about the testing approach, setup, and results for the Production Experience Showcase project. The project uses a robust testing framework to ensure code quality, reliability, and functionality.

## Test Coverage and Structure

### Test Files

The backend service is tested with the following test files:

| Test File             | Description                          | Tests   |
| --------------------- | ------------------------------------ | ------- |
| `api.test.js`         | Tests API endpoints                  | 4 tests |
| `api-docs.test.js`    | Tests Swagger API documentation      | 3 tests |
| `container.test.js`   | Tests Docker container configuration | 9 tests |
| `database.test.js`    | Tests database connection handling   | 3 tests |
| `environment.test.js` | Tests environment variable handling  | 3 tests |
| `health.test.js`      | Tests health check endpoint          | 4 tests |
| `metrics.test.js`     | Tests Prometheus metrics endpoint    | 3 tests |

Total: 29 tests across 7 test files

### Test Directory Structure

```
backend/
├── tests/
│   ├── api.test.js         # Tests for API endpoints
│   ├── api-docs.test.js    # Tests for Swagger API documentation
│   ├── container.test.js   # Tests for Docker container configuration
│   ├── database.test.js    # Tests for database connection handling
│   ├── environment.test.js # Tests for environment variable handling
│   ├── health.test.js      # Tests for health check endpoint
│   └── metrics.test.js     # Tests for the Prometheus metrics endpoint
```

### Coverage Metrics

The current test coverage metrics are:

| Metric     | Coverage |
| ---------- | -------- |
| Statements | 87.01%   |
| Branches   | 75%      |
| Functions  | 55.55%   |
| Lines      | 86.84%   |

Uncovered lines: 140, 231-235, 241-244 in index.js

## Testing Philosophy and Approach

The testing approach follows these key principles:

1. **Isolation**: Each test is independent and does not rely on the state from other tests.
2. **Mocking**: External dependencies are mocked to ensure tests are fast and reliable.
3. **Coverage**: Tests cover critical paths and edge cases.
4. **Readability**: Tests are clear and descriptive, serving as documentation.

## Testing Strategies

### Mocking Strategy

The tests use extensive mocking to isolate components:

1. **Database Mocking**: The PostgreSQL client is mocked to avoid actual database connections during testing:

   ```javascript
   // Example of database mocking
   jest.mock('pg', () => {
     const mPool = {
       connect: jest.fn(),
       end: jest.fn(),
     };
     return { Pool: jest.fn(() => mPool) };
   });
   ```

2. **Express Mocking**: The Express application is mocked to test routing without starting a server:

   ```javascript
   // Example of request/response mocking
   const mockRequest = () => ({});
   const mockResponse = () => {
     const res = {};
     res.status = jest.fn().mockReturnValue(res);
     res.json = jest.fn().mockReturnValue(res);
     return res;
   };
   ```

3. **Prometheus Mocking**: The Prometheus client is mocked to test metrics collection:
   ```javascript
   // Example of Prometheus client mocking
   jest.mock('prom-client', () => ({
     Registry: jest.fn().mockImplementation(() => ({
       metrics: jest.fn().mockResolvedValue('metrics data'),
       contentType: 'text/plain',
       registerMetric: jest.fn(),
     })),
     Counter: jest.fn().mockImplementation(() => ({
       inc: jest.fn(),
     })),
     Histogram: jest.fn().mockImplementation(() => ({
       observe: jest.fn(),
       labels: jest.fn().mockReturnThis(),
     })),
     collectDefaultMetrics: jest.fn(),
   }));
   ```

### Environment Isolation

Tests run in an isolated environment to prevent interference:

- Each test preserves and restores the original environment variables.
- The module cache is reset between tests to ensure a fresh application instance.
- The `NODE_ENV=test` setting is used to disable database connections in test mode.

## Test Categories

The test suite is organized into several categories:

1. **API Endpoints**: Tests that the API endpoints respond correctly with appropriate status codes and content types.

   - `GET /health`: Health check endpoint returns correct status
   - `GET /metrics`: Prometheus metrics endpoint returns metrics data

2. **API Documentation**: Tests that the Swagger documentation is correctly generated and accessible.

   - Tests that /api-docs returns 200 with the correct content

3. **Database Connection**: Tests database connection handling and error scenarios.

   - Tests connection pool creation
   - Tests error handling during connection failures
   - Tests graceful connection closure

4. **Metrics Collection**: Tests that the Prometheus metrics are correctly collected and formatted.

   - Tests that metrics endpoint returns correct content type
   - Tests default metrics collection
   - Tests custom metrics registration

5. **Environment Variables**: Tests that the application correctly uses environment variables for configuration.

   - Tests default values when environment variables are missing
   - Tests override behavior when environment variables are present
   - Tests validation of required environment variables

6. **Health Checks**: Tests that the health check endpoint correctly reports system health.

   - Tests successful health check response
   - Tests database connectivity check
   - Tests error handling during database connection failures
   - Tests health check response format

7. **Container Configuration**: Tests Docker container configuration.
   - Tests Dockerfile existence and validity
   - Tests port exposure configuration
   - Tests environment variable configuration

## Recent Implementation Testing

### Database Logging Middleware

The newly implemented middleware for database logging of all non-metric HTTP requests should be tested for:

1. **Insertion Functionality**: Verify that request information is correctly inserted into the metrics table
2. **Request Path Filtering**: Ensure /metrics requests are not logged to avoid clutter
3. **Error Handling**: Confirm proper error handling during database failures
4. **Performance Impact**: Check that logging doesn't significantly impact response time

Test examples would include:

```javascript
// Example test for database logging middleware
test('should log non-metrics requests to database', async () => {
  // Mock setup
  const client = { query: jest.fn().mockResolvedValue({}), release: jest.fn() };
  pool.connect.mockResolvedValue(client);

  // Mock request/response
  const req = { path: '/test', method: 'GET' };
  const res = { statusCode: 200, on: jest.fn() };

  // Call middleware
  const middleware = app._router.stack.find(layer => layer.name === 'middleware');
  await middleware.handle(req, res, jest.fn());

  // Trigger finish event
  const finishCallback = res.on.mock.calls[0][1];
  await finishCallback();

  // Verify database insertion
  expect(client.query).toHaveBeenCalledWith(
    'INSERT INTO metrics(endpoint, method, status_code, duration_ms) VALUES($1, $2, $3, $4)',
    ['/test', 'GET', 200, expect.any(Number)]
  );
});
```

## Running Tests

Tests can be run using the following npm scripts:

```bash
# Run all tests
npm test

# Run tests in watch mode (for development)
npm run test:watch

# Run tests with coverage report
npm run test:coverage

# Run a specific test file
npx jest tests/api.test.js
```

## Test Results Interpretation

Test results are displayed in the console with a summary of passed, failed, and skipped tests. A coverage report is generated to identify areas that need additional testing.

### Addressing Test Failures

When tests fail, follow these steps:

1. Read the error message to understand what failed
2. Check the test file and line number
3. Review the code being tested
4. Fix the issue in the application code or update the test if expectations have changed

## Future Test Enhancements

The following enhancements are planned for the test suite:

1. **Integration Tests**: Add tests that verify the interaction between components.
2. **Load Tests**: Implement performance and load testing to ensure the application performs well under stress.
3. **Security Tests**: Add tests for security vulnerabilities.
4. **End-to-End Tests**: Add tests that verify the entire system works together.
5. **Improve Function Coverage**: Increase the function coverage from the current 55.55%.
6. **Database Logging Tests**: Add comprehensive tests for the newly implemented database logging middleware.

## Conclusion

The testing setup provides a solid foundation for ensuring code quality and reliability. The tests are comprehensive, covering various aspects of the application, and are designed to be maintainable and extensible.
