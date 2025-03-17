# Container Compatibility Testing

## Overview

This document covers the testing approach for container compatibility in our backend service. The container tests (`container.test.js`) are crucial for ensuring that our Docker containers are properly configured and will work in production environments.

## Test Strategy

The container compatibility tests verify:

1. The correct configuration of Dockerfiles for all services (Backend, Prometheus, Grafana)
2. The proper port exposure for container networking
3. The appropriate base images and configurations
4. The availability of required package configuration

## Testing Approach

These tests use Node.js file system operations to read and analyze the Dockerfile contents directly. This approach is CI-friendly because:

1. It doesn't require building or running actual containers
2. It doesn't depend on external services
3. It performs static analysis of configuration files
4. It has minimal dependencies

## Test Categories

### Backend Dockerfile Tests

```javascript
describe('Backend Dockerfile', () => {
  it('should have valid EXPOSE directive for container port', () => {
    expect(dockerfileContent).toMatch(/EXPOSE \d+/);
  });

  it('should use proper Node.js base image', () => {
    expect(dockerfileContent).toMatch(/FROM node:/);
  });

  it('should copy package files for dependency installation', () => {
    expect(dockerfileContent).toMatch(/COPY package\*.json/);
  });

  it('should run npm install for dependency installation', () => {
    expect(dockerfileContent).toMatch(/npm install/);
  });

  it('should specify a CMD or ENTRYPOINT for container startup', () => {
    const hasCMD = dockerfileContent.match(/CMD/);
    const hasENTRYPOINT = dockerfileContent.match(/ENTRYPOINT/);
    expect(hasCMD || hasENTRYPOINT).toBeTruthy();
  });
});
```

### Prometheus Dockerfile Tests

```javascript
describe('Prometheus Dockerfile', () => {
  it('should use Prometheus as base image', () => {
    expect(dockerfilePromContent).toMatch(/FROM prom\/prometheus/);
  });

  it('should copy prometheus configuration file', () => {
    expect(dockerfilePromContent).toMatch(/COPY prometheus\.yml/);
  });

  it('should expose Prometheus default port', () => {
    expect(dockerfilePromContent).toMatch(/EXPOSE 9090/);
  });
});
```

### Grafana Dockerfile Tests

```javascript
describe('Grafana Dockerfile', () => {
  it('should use Grafana as base image', () => {
    expect(dockerfileGrafanaContent).toMatch(/FROM grafana\/grafana/);
  });

  it('should copy provisioning configs', () => {
    expect(dockerfileGrafanaContent).toMatch(/COPY provisioning/);
  });

  it('should expose Grafana default port', () => {
    expect(dockerfileGrafanaContent).toMatch(/EXPOSE 3000/);
  });
});
```

### Package Configuration Tests

```javascript
describe('Backend Package Configuration', () => {
  it('should have proper start script', () => {
    expect(packageJson.scripts).toHaveProperty('start');
    expect(packageJson.scripts.start).toMatch(/node/);
  });

  it('should list required dependencies', () => {
    const requiredDeps = ['express', 'pg', 'prom-client'];
    requiredDeps.forEach(dep => {
      expect(packageJson.dependencies).toHaveProperty(dep);
    });
  });
});
```

## CI Reliability

The container tests are considered "CI reliable" for several reasons:

1. **No External Dependencies**: Tests don't require databases, AWS services, or other external systems
2. **Fast Execution**: Tests are quick to run since they only perform file operations
3. **Stable Assertions**: Tests verify the presence of specific patterns rather than exact implementations
4. **Environment Agnostic**: Tests work the same way regardless of the environment they run in

## Benefits

Testing container compatibility offers several advantages:

1. **Early Issue Detection**: Catches misconfigurations before deploying to production
2. **Documentation**: Tests serve as documentation for how containers should be configured
3. **Consistency**: Ensures consistent container setup across environments
4. **Reliability**: Prevents common deployment issues related to container configuration

## Troubleshooting

If container tests fail, check:

1. Changes to Dockerfile structure or directives
2. Missing package dependencies
3. Incorrect port exposure configuration
4. Missing or renamed configuration files referenced in Dockerfiles

## Integration with CI/CD

These tests are particularly valuable in CI/CD pipelines because they:

1. Run quickly without requiring container builds
2. Provide early validation before more resource-intensive steps
3. Catch configuration issues that might only manifest during deployment
4. Help maintain consistent container behavior across environments
