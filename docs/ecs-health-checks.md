# ECS Health Checks Documentation

## Overview

Health checks are critical for ensuring that containers running in ECS are functioning correctly and can handle traffic. This document details the health check configuration for the prod-e application and provides best practices for ECS health checks.

## Current Configuration

The ECS task definition includes the following health check configuration:

```json
"healthCheck": {
  "command": ["CMD-SHELL", "node -e \"require('http').request({host: 'localhost', port: 3000, path: '/health', timeout: 2000}, (res) => { process.exit(res.statusCode !== 200 ? 1 : 0); }).on('error', () => process.exit(1)).end()\""],
  "interval": 30,
  "timeout": 5,
  "retries": 3,
  "startPeriod": 60
}
```

### Key Components

- **Command**: Uses Node.js to make an HTTP request to the `/health` endpoint
- **Interval**: Checks run every 30 seconds
- **Timeout**: Each check times out after 5 seconds
- **Retries**: Allows 3 failed checks before marking the container as unhealthy
- **Start Period**: Gives the container 60 seconds to initialize before beginning health checks

## Health Check Endpoint

The application exposes a `/health` endpoint that returns status information:

```json
{
  "status": "ok",
  "timestamp": "2025-03-14T07:11:18.325Z",
  "database": "connected"
}
```

The endpoint performs the following validations:

1. Verifies the application is running
2. Checks database connectivity
3. Returns a 200 OK response if all systems are operational

## Previous Issues

The health check was initially configured to use `curl`:

```json
"healthCheck": {
  "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
  "interval": 30,
  "timeout": 5,
  "retries": 3,
  "startPeriod": 60
}
```

This approach presented the following problems:

- The application container did not include `curl`, causing health checks to fail
- Image size increased when adding `curl` as a dependency
- Error handling was limited compared to the Node.js approach

## Benefits of Node.js-based Health Checks

Using Node.js for health checks provides several advantages:

1. **Dependency Reduction**: Eliminates the need for additional packages like `curl`
2. **Improved Error Handling**: Can distinguish between different types of failures
3. **Performance**: Lighter weight than spawning a new process
4. **Consistency**: Uses the same runtime as the application

## Health Check Design Considerations

### Response Time

Health checks should complete quickly to avoid:

- Consuming container resources
- Timing out incorrectly
- Delaying task replacement when truly unhealthy

### Depth of Validation

Consider the appropriate depth for health checks:

- **Shallow Checks**: Faster, less resource-intensive, but may miss issues
- **Deep Checks**: More thorough, but slower and more resource-intensive

### Graceful Degradation

Not all subsystem failures should result in container replacement:

- Critical systems (e.g., database) should fail health checks
- Non-critical systems should report status but not fail the container

## Troubleshooting Health Check Failures

### Common Issues and Resolutions

1. **Port Mismatch**

   - **Issue**: Health check targets a different port than the application
   - **Resolution**: Verify port configuration in both container and health check

2. **Timeout Too Short**

   - **Issue**: Health check times out before the application can respond
   - **Resolution**: Increase timeout value to accommodate typical response times

3. **Insufficient Start Period**

   - **Issue**: Application needs more time to initialize
   - **Resolution**: Increase startPeriod to allow for longer initialization

4. **Path Not Found**
   - **Issue**: Health check targets non-existent endpoint
   - **Resolution**: Verify health check path matches application endpoint

### Debugging ECS Health Checks

To diagnose health check issues:

1. View task details in ECS console
2. Check container logs for health check failures
3. Test health check endpoint directly from within the container
4. Verify networking configuration allows health check requests

## Best Practices

1. **Keep Health Checks Lightweight**: Minimize resource usage and response time
2. **Include Meaningful Status Information**: Return useful diagnostic data
3. **Test Health Checks Locally**: Verify before deployment
4. **Use Appropriate Timeouts and Intervals**: Balance responsiveness with overhead
5. **Include Critical Dependencies**: Check essential subsystems
6. **Log Health Check Results**: Aid in troubleshooting
