/**
 * Global Jest setup file
 *
 * This file runs before all tests to set up the test environment consistently
 */

// Set test environment variables
process.env.NODE_ENV = 'test';

// This helps with async operations in tests
jest.setTimeout(10000);

// Set up advanced mocking behavior
beforeEach(() => {
  // Reset all mocks to their initial state
  jest.clearAllMocks();

  // Clear cached modules to ensure clean instantiation
  jest.resetModules();

  // By default, silence console during tests to reduce noise
  jest.spyOn(console, 'log').mockImplementation(() => {});
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'warn').mockImplementation(() => {});
});

// Create a global afterEach to ensure clean teardown
afterEach(() => {
  // Restore console functions
  jest.restoreAllMocks();
});
