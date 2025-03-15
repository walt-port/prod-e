# Local Development Setup

## Overview

This document provides step-by-step instructions for setting up a local development environment for the Production Experience Showcase project. It covers prerequisites, installation steps, configuration, and common development workflows.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Repository Setup](#repository-setup)
- [Environment Configuration](#environment-configuration)
- [Running the Project](#running-the-project)
- [Developing Components](#developing-components)
- [Testing](#testing)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)

## Prerequisites

Before starting, ensure you have the following tools installed on your development machine:

| Tool      | Version | Purpose                     |
| --------- | ------- | --------------------------- |
| Node.js   | ≥ 18.x  | JavaScript runtime          |
| npm       | ≥ 9.x   | Package manager             |
| AWS CLI   | ≥ 2.x   | AWS resource management     |
| Terraform | ≥ 1.5.0 | Infrastructure provisioning |
| Docker    | Latest  | Container management        |
| Git       | Latest  | Version control             |

### Installing Prerequisites

#### Node.js and npm

```bash
$ curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
$ sudo apt-get install -y nodejs
```

For other platforms, see the [Node.js downloads page](https://nodejs.org/en/download/).

#### AWS CLI

```bash
$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
$ unzip awscliv2.zip
$ sudo ./aws/install
```

#### Terraform

```bash
$ wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
$ echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
$ sudo apt update && sudo apt install terraform
```

#### Docker

```bash
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
```

For detailed instructions, see the [Docker installation guide](https://docs.docker.com/engine/install/).

## Repository Setup

1. Clone the repository:

   ```bash
   $ git clone https://github.com/your-username/prod-e.git
   $ cd prod-e
   ```

2. Install dependencies:

   ```bash
   $ npm install
   $ npx cdktf get
   ```

## Environment Configuration

1. Create a `.env` file in the project root with the following variables:

   ```
   AWS_REGION=us-west-2
   ENVIRONMENT=dev
   DB_USER=postgres
   DB_PASSWORD=your_local_password
   ```

2. Configure AWS credentials:

   ```bash
   $ aws configure
   ```

   Enter your AWS Access Key ID, Secret Access Key, default region (us-west-2), and output format (json).

## Running the Project

### Infrastructure Development

1. Synthesize Terraform configuration:

   ```bash
   $ npm run synth
   ```

2. Generate a plan to see what changes would be made:

   ```bash
   $ cd cdktf.out/stacks/prod-e
   $ terraform plan
   ```

3. For local infrastructure testing, use LocalStack:

   ```bash
   $ docker run -d -p 4566:4566 -p 4510-4559:4510-4559 localstack/localstack
   ```

### Backend Development

1. Start the backend in development mode:

   ```bash
   $ cd backend
   $ npm run dev
   ```

2. Access the backend API at [http://localhost:3000](http://localhost:3000)

## Developing Components

### Infrastructure Changes

1. Modify the infrastructure code in the `infrastructure/` directory.
2. Run `npm run synth` to generate updated Terraform configuration.
3. Preview changes with `terraform plan`.

### Backend Changes

1. Modify backend code in the `backend/` directory.
2. Tests will automatically run on file changes when using `npm run dev`.

## Testing

### Running Infrastructure Tests

```bash
$ npm test
```

### Running Backend Tests

```bash
$ cd backend
$ npm test
```

### Running End-to-End Tests

```bash
$ npm run test:e2e
```

## Common Tasks

### Building Docker Images Locally

```bash
$ cd backend
$ docker build -t prod-e-backend:local .
```

### Generating TypeScript Types

```bash
$ npm run generate-types
```

### Linting and Formatting

```bash
$ npm run lint
$ npm run format
```

## Troubleshooting

### Common Issues

| Issue                          | Solution                                                                         |
| ------------------------------ | -------------------------------------------------------------------------------- |
| Authentication errors with AWS | Ensure AWS credentials are correctly configured with `aws configure`             |
| Missing dependencies           | Run `npm install` to ensure all dependencies are installed                       |
| Port conflicts                 | Check for processes using the same ports (3000 for backend, 4566 for LocalStack) |
| Terraform version issues       | Ensure you're using Terraform ≥ 1.5.0 (`terraform -v`)                           |

### LocalStack Connectivity Issues

If you encounter issues connecting to LocalStack:

```bash
$ docker logs localstack
```

Check that the container is running:

```bash
$ docker ps | grep localstack
```

## Related Documentation

- [Infrastructure Overview](./overview.md)
- [Testing Strategy](./testing.md)
- [Deployment Guide](./deployment-guide.md)

---

**Last Updated**: 2025-03-15
**Version**: 1.0
