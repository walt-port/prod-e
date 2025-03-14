/**
 * API Endpoint Tests
 *
 * Tests the API endpoints:
 * - Validates response status codes
 * - Tests response content
 * - Verifies error handling
 */

const request = require('supertest');
const express = require('express');

// Mock the pg module
jest.mock('pg', () => {
  const mockClient = {
    query: jest.fn().mockResolvedValue({}),
    release: jest.fn(),
  };

  const mockPool = {
    connect: jest.fn().mockResolvedValue(mockClient),
    on: jest.fn(),
  };

  return {
    Pool: jest.fn(() => mockPool),
  };
});

// Mock the prom-client module
jest.mock('prom-client', () => {
  const mockCounter = {
    inc: jest.fn(),
    labels: jest.fn().mockReturnThis(),
  };

  const mockHistogram = {
    observe: jest.fn(),
    labels: jest.fn().mockReturnThis(),
  };

  const mockRegistry = {
    registerMetric: jest.fn(),
    metrics: jest.fn().mockResolvedValue('mock metrics data'),
    contentType: 'text/plain; version=0.0.4; charset=utf-8',
  };

  return {
    Counter: jest.fn(() => mockCounter),
    Histogram: jest.fn(() => mockHistogram),
    Registry: jest.fn(() => mockRegistry),
    collectDefaultMetrics: jest.fn(),
  };
});

describe('API Endpoints', () => {
  let app;
  let originalEnv;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };

    // Clear module cache to ensure fresh app instance
    jest.resetModules();

    // Reset mocks
    jest.clearAllMocks();

    // Set test environment
    process.env.NODE_ENV = 'test';

    // Mock console methods to avoid cluttering test output
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});

    // Import the app
    app = require('../index');
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
  });

  describe('GET /health', () => {
    it('should return 200 status code and health information', async () => {
      const response = await request(app).get('/health');
      expect(response.statusCode).toBe(200);
      expect(response.body).toHaveProperty('status');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('database');
      expect(response.body.status).toBe('ok');
      expect(response.body.database).toBe('skipped (test mode)');
    });
  });

  describe('GET /metrics', () => {
    it('should return 200 status code and metrics data', async () => {
      const response = await request(app).get('/metrics');
      expect(response.statusCode).toBe(200);
      expect(response.text).toBe('mock metrics data');
      expect(response.headers['content-type']).toBe('text/plain; version=0.0.4; charset=utf-8');
    });
  });

  describe('GET /api-docs', () => {
    it('should return a successful response for API docs', async () => {
      const response = await request(app).get('/api-docs');
      expect(response.statusCode).toBe(301);
    });
  });

  describe('GET /nonexistent-route', () => {
    it('should return 404 status code for nonexistent routes', async () => {
      const response = await request(app).get('/nonexistent-route');
      expect(response.statusCode).toBe(404);
    });
  });
});
