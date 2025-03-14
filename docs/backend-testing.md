# Backend Testing Documentation

## Overview

This document describes the testing strategy and implementation for the backend service of the Production Experience Showcase project. The backend is tested using Jest as the test runner and assertion library, along with several supporting tools for mocking and API testing.

## Testing Architecture

The backend testing is organized into several categories:

1. **API Endpoint Tests**: Verify that the API endpoints return the expected responses
2. **Environment Variable Tests**: Ensure proper handling of configuration through environment variables
3. **Container Tests**: Validate the Docker container configuration
4. **Database Interaction Tests**: Test database connection handling and error scenarios

## Test Setup

### Dependencies

The testing setup uses the following dependencies:

- **Jest**: Test runner and assertion library
- **Supertest**: HTTP assertions for testing API endpoints
- **Jest-Mock-Extended**: Enhanced mocking capabilities
- **pg-mem**: In-memory PostgreSQL database for testing

### Directory Structure

Tests are organized in the `backend/tests` directory, with each test file focusing on a specific aspect of the application:

```
backend/
├── tests/
│   ├── api.test.js         # Tests for API endpoints
│   ├── api-docs.test.js    # Tests for Swagger API documentation
│   ├── container.test.js   # Tests for Docker container configuration
│   ├── database.test.js    # Tests for database connection handling
│   ├── environment.test.js # Tests for environment variable handling
│   ├── health.test.js      # Tests for the health check endpoint
│   └── metrics.test.js     # Tests for the Prometheus metrics endpoint
```

## Testing Strategies

### Mocking

The tests use extensive mocking to isolate components and test them independently:

1. **Database Mocking**: The PostgreSQL client is mocked to avoid actual database connections
2. **Express Mocking**: The Express application is mocked to test routing without starting a server
3. **Prometheus Mocking**: The Prometheus client is mocked to test metrics collection

### Environment Isolation

Tests run in an isolated environment to prevent interference:

1. Each test preserves and restores the original environment variables
2. The module cache is reset between tests to ensure a fresh application instance
3. The `NODE_ENV=test` setting is used to disable database connections in test mode

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

## Test Categories

### API Endpoint Tests

These tests verify that the API endpoints return the expected responses:

- **Health Endpoint**: Tests the `/health` endpoint returns correct status and database information
- **Metrics Endpoint**: Tests the Prometheus metrics endpoint returns metrics data with correct content type
- **API Documentation**: Tests the Swagger UI documentation endpoint is accessible
- **Error Handling**: Tests that nonexistent routes return 404 status codes

### Environment Variable Tests

These tests ensure that the application correctly handles configuration through environment variables:

- Default values for missing environment variables
- Custom configuration through environment variables
- Environment-specific behavior (dev, test, prod)

### Container Tests

These tests validate the Docker container configuration:

- Multi-stage build for security and size optimization
- Non-root user for security
- Health check configuration
- Production environment settings

### Database Tests

These tests validate the database connection and error handling:

- Database connection configuration from environment variables
- Skipping database connection in test mode
- Handling database connection errors gracefully
- Database initialization with table creation

## Best Practices

1. **Isolation**: Each test should be independent and not rely on the state from other tests
2. **Mocking**: External dependencies should be mocked to ensure tests are fast and reliable
3. **Coverage**: Aim for high test coverage, especially for critical paths
4. **Readability**: Tests should be clear and descriptive, serving as documentation

## Future Enhancements

1. **Integration Tests**: Add tests that verify the interaction between components
2. **Load Tests**: Implement performance and load testing
3. **Security Tests**: Add tests for security vulnerabilities
4. **End-to-End Tests**: Add tests that verify the entire system works together
