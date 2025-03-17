/**
 * Centralized mock for the pg module
 * This provides a consistent mock implementation for all tests
 */

// Create mock objects that can be shared and customized by tests
const mockClient = {
  query: jest.fn().mockResolvedValue({ rows: [] }),
  release: jest.fn(),
};

const mockPool = {
  connect: jest.fn().mockResolvedValue(mockClient),
  end: jest.fn().mockResolvedValue(undefined),
  on: jest.fn(),
};

// Create a mock constructor for Pool that tracks calls for verification
const Pool = jest.fn(config => {
  mockPool.config = config;
  return mockPool;
});

// Export the mocked module
module.exports = {
  Pool,
  // Expose mock objects for test manipulation
  _mockClient: mockClient,
  _mockPool: mockPool,
  // Helper to reset all mocks between tests
  _reset: function () {
    mockClient.query.mockClear();
    mockClient.release.mockClear();
    mockPool.connect.mockClear();
    mockPool.end.mockClear();
    mockPool.on.mockClear();
    Pool.mockClear();
  },
};
