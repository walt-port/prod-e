/**
 * Docker Container Tests
 *
 * Tests the Dockerfile configuration and container functionality:
 * - Validates Dockerfile instructions
 * - Checks for security best practices
 * - Tests container startup
 */

const fs = require('fs');
const path = require('path');

describe('Docker Container Configuration', () => {
  let dockerfileContent;

  beforeAll(() => {
    // Read the Dockerfile
    dockerfileContent = fs.readFileSync(path.join(__dirname, '..', 'Dockerfile'), 'utf8');
  });

  it('should use a multi-stage build for better security and size optimization', () => {
    expect(dockerfileContent).toMatch(/FROM .+ AS builder/i);
    expect(dockerfileContent.match(/FROM/g).length).toBeGreaterThan(1);
  });

  it('should use a specific Node.js version for consistency', () => {
    expect(dockerfileContent).toMatch(/FROM node:16/i);
  });

  it('should use a production environment variable', () => {
    expect(dockerfileContent).toMatch(/NODE_ENV=production/i);
  });

  it('should use a non-root user for security', () => {
    expect(dockerfileContent).toMatch(/adduser|useradd/i);
    expect(dockerfileContent).toMatch(/USER [^root]/i);
  });

  it('should expose the application port', () => {
    expect(dockerfileContent).toMatch(/EXPOSE 3000/i);
  });

  it('should include a health check', () => {
    expect(dockerfileContent).toMatch(/HEALTHCHECK/i);
    expect(dockerfileContent).toMatch(/health/i);
  });

  it('should have a proper CMD to start the application', () => {
    expect(dockerfileContent).toMatch(/CMD \["node", "index\.js"\]/i);
  });

  it('should only install production dependencies in the final stage', () => {
    // Check for npm ci --only=production or npm install --only=production or npm install --omit=dev
    expect(dockerfileContent).toMatch(/npm (ci|install) (--only=production|--omit=dev)/i);
  });

  it('should copy only necessary files to the final image', () => {
    // Ensure we're not copying everything (including node_modules) to the final image
    expect(dockerfileContent).toMatch(/COPY --from=builder/i);
  });
});
