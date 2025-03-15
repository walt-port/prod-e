# Contributing to Production Experience Showcase (prod-e)

Thank you for your interest in contributing to the Production Experience Showcase! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project. We aim to foster an inclusive and welcoming community.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion for improving the project:

1. Check if the issue already exists in the [GitHub Issues](https://github.com/walt-port/prod-e/issues)
2. If not, create a new issue with a descriptive title and detailed information:
   - Steps to reproduce the bug
   - Expected behavior
   - Actual behavior
   - Screenshots or logs if applicable
   - Environment information (OS, Node.js version, etc.)

### Submitting Changes

1. Fork the repository
2. Create a new branch with a descriptive name: `git checkout -b feature/your-feature-name` or `git checkout -b fix/issue-you-are-fixing`
3. Make your changes
4. Ensure tests pass: `npm test`
5. Commit your changes with a clear commit message
6. Push to your fork: `git push origin your-branch-name`
7. Submit a pull request to the main repository

### Pull Request Process

1. Update the README.md or documentation with details of changes if applicable
2. Update or add tests that verify your changes
3. Ensure your code follows the project's style guidelines
4. Your pull request will be reviewed by the maintainers
5. Address any requested changes

## Development Setup

To set up the project for development:

1. Clone the repository: `git clone https://github.com/walt-port/prod-e.git`
2. Install dependencies: `npm install`
3. Generate CDKTF providers: `cdktf get`
4. Follow the [Local Development Guide](docs/guides/local-development.md) for more details

## Coding Standards

- Follow the existing code style in the project
- Write meaningful commit messages
- Add comments to explain complex logic
- Write tests for new features or bug fixes
- Update documentation for significant changes

## Testing

- Ensure all tests pass before submitting a pull request: `npm test`
- Add new tests for new features or bug fixes
- Maintain or improve test coverage

## Documentation

- Update documentation for any changes to the API, functionality, or configuration
- Keep the README.md file up-to-date
- Document new features or significant changes

## Additional Resources

- [Project Documentation](docs/documentation-inventory.md)
- [Local Development Guide](docs/guides/local-development.md)
- [Deployment Guide](docs/guides/deployment-guide.md)

## Questions?

If you have any questions about contributing, please open an issue or contact the project maintainers.
