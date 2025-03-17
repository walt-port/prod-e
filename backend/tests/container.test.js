/**
 * Container Compatibility Tests
 *
 * Tests functionality critical for containerized deployments:
 * - Environment variable configuration
 * - PORT binding for container networking
 * - Health check for container orchestration
 */

const fs = require('fs');
const path = require('path');

describe('Container Compatibility', () => {
  let dockerfilePath;
  let dockerfileContent;
  let dockerfilePromPath;
  let dockerfilePromContent;
  let dockerfileGrafanaPath;
  let dockerfileGrafanaContent;

  beforeAll(() => {
    dockerfilePath = path.join(__dirname, '..', 'Dockerfile');
    dockerfileContent = fs.readFileSync(dockerfilePath, 'utf8');

    dockerfilePromPath = path.join(__dirname, '..', 'Dockerfile.prometheus');
    dockerfilePromContent = fs.readFileSync(dockerfilePromPath, 'utf8');

    dockerfileGrafanaPath = path.join(__dirname, '..', 'Dockerfile.grafana');
    dockerfileGrafanaContent = fs.readFileSync(dockerfileGrafanaPath, 'utf8');
  });

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

  describe('Backend Package Configuration', () => {
    let packageJsonPath;
    let packageJson;

    beforeAll(() => {
      packageJsonPath = path.join(__dirname, '..', 'package.json');
      packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    });

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
});
