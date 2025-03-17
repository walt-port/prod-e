/**
 * Environment Variable Tests
 *
 * Tests the application's handling of environment variables:
 * - Default values for missing environment variables
 * - Processing of database configuration
 * - Handling of different environments (dev, test, prod)
 */

// Mock express before requiring any modules
jest.mock('express', () => {
  const mockListen = jest.fn();
  const mockUse = jest.fn();
  const mockGet = jest.fn();
  const mockStatic = jest.fn(() => 'static-middleware');

  const mockExpress = jest.fn(() => ({
    use: mockUse,
    get: mockGet,
    listen: mockListen,
  }));

  mockExpress.static = mockStatic;
  return mockExpress;
});

// Mock swagger-ui-express
jest.mock('swagger-ui-express', () => ({
  serve: ['swagger-ui-middleware'],
  setup: jest.fn(() => 'swagger-ui-setup'),
}));

// Mock swagger-jsdoc
jest.mock('swagger-jsdoc', () => {
  return jest.fn(() => ({ openapi: '3.0.0' }));
});

// Mock prom-client
jest.mock('prom-client', () => {
  const mockCounter = jest.fn().mockImplementation(() => ({
    inc: jest.fn(),
    labels: jest.fn().mockReturnThis(),
  }));

  const mockHistogram = jest.fn().mockImplementation(() => ({
    observe: jest.fn(),
    labels: jest.fn().mockReturnThis(),
  }));

  const mockRegister = {
    metrics: jest.fn().mockResolvedValue('mock metrics'),
    registerMetric: jest.fn(),
  };

  return {
    Counter: mockCounter,
    Histogram: mockHistogram,
    Registry: jest.fn(() => mockRegister),
    collectDefaultMetrics: jest.fn(),
  };
});

// Get access to the pg mock
const pg = require('pg');

describe('Environment Variable Handling', () => {
  let originalEnv;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };

    // Configure the pg mock
    pg._reset();
  });

  afterEach(() => {
    // Restore original environment
    process.env = { ...originalEnv };
  });

  it('should use default port when PORT is not set', () => {
    // Remove PORT from environment
    delete process.env.PORT;

    // Import the app
    const app = require('../index');
    const express = require('express');

    // Check if listen was called with default port
    expect(express().listen).toHaveBeenCalledWith(3000, expect.any(Function));
  });

  it('should use environment PORT when set', () => {
    // Set custom PORT
    process.env.PORT = '8080';

    // Import the app
    const app = require('../index');
    const express = require('express');

    // Check if listen was called with custom port
    expect(express().listen).toHaveBeenCalledWith(8080, expect.any(Function));
  });

  it('should use database configuration from environment variables', async () => {
    // Set environment to production with DB config
    process.env.NODE_ENV = 'production';
    process.env.DB_HOST = 'testhost';
    process.env.DB_PORT = '5432';
    process.env.DB_NAME = 'testdb';
    process.env.DB_USER = 'testuser';
    process.env.DB_PASSWORD = 'testpass';

    // Import the app
    require('../index');

    // Wait for any async operations
    await new Promise(resolve => setTimeout(resolve, 100));

    // Check the Pool constructor was called with correct config
    expect(pg.Pool).toHaveBeenCalled();

    // Get the config from the mock pool
    const poolConfig = pg._mockPool.config;

    // Verify the config matches our environment variables
    expect(poolConfig).toEqual({
      host: 'testhost',
      port: '5432',
      database: 'testdb',
      user: 'testuser',
      password: 'testpass',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
  });

  it('should not initialize database in test mode', () => {
    // Set test environment
    process.env.NODE_ENV = 'test';

    // Import the app
    require('../index');

    // Verify Pool constructor was not called in test mode
    expect(pg.Pool).not.toHaveBeenCalled();
  });
});
