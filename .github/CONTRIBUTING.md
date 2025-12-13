# Contributing to faneX-ID Home Assistant Add-on

First off, thank you for considering contributing to the faneX-ID Home Assistant Add-on! 🎉

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible using our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure your code follows the existing style
4. Make sure your code lints
5. Issue that pull request!

## Development Setup

### Prerequisites

- Docker
- Home Assistant development environment
- Git

### Local Development

1. Clone your fork:
```bash
git clone https://github.com/YOUR_USERNAME/homeassistant-addon.git
cd homeassistant-addon
```

2. Make your changes in the `fanexid/` directory

3. Test locally by installing the add-on from your local repository:
   - Add `file:///path/to/your/homeassistant-addon/` as a repository in Home Assistant
   - Install and test the add-on

### Testing

Before submitting a pull request:

1. Test the add-on installation
2. Test the add-on startup
3. Test basic functionality
4. Check logs for errors
5. Test upgrades if applicable

## Style Guidelines

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line
- Use conventional commits format:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation changes
  - `chore:` for maintenance tasks

### Coding Style

- Follow the existing code style
- Use meaningful variable and function names
- Comment complex logic
- Keep functions small and focused

## Documentation

- Update the README.md if you change functionality
- Update DOCS.md with detailed configuration changes
- Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/)
- Add translations if you add new configuration options

## Release Process

Releases are automated through GitHub Actions:

1. Update CHANGELOG.md
2. Create a new release on GitHub
3. GitHub Actions will build and publish the Docker images
4. The add-on will be available for installation

## Questions?

Feel free to open an issue with your question, or reach out on the [Home Assistant Community Forum](https://community.home-assistant.io/).

Thank you for contributing! 🙏
