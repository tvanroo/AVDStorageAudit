# Contributing to AVD Storage Audit

Thank you for your interest in contributing to the AVD Storage Audit project! This document provides guidelines for contributing to this repository.

## 🤝 How to Contribute

### Reporting Issues
- Use the GitHub Issues tab to report bugs or request features
- Provide clear descriptions and reproduction steps for bugs
- Include relevant system information (Azure region, AVD configuration, etc.)

### Submitting Changes
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 🧪 Testing Guidelines

### ARM Template Testing
- Validate templates using Azure Resource Manager Template Toolkit (ARM TTK)
- Test deployments in a non-production environment
- Ensure templates follow Azure best practices

### PowerShell Script Testing
- Test scripts with PowerShell 5.1 and 7.x
- Verify error handling and parameter validation
- Test with different Azure subscription configurations

## 📋 Code Standards

### ARM Templates
- Use consistent parameter naming conventions
- Include comprehensive metadata descriptions
- Follow Azure naming conventions for resources
- Use variables for computed values

### PowerShell Scripts
- Follow PowerShell best practices and style guidelines
- Use approved verbs for function names
- Include proper error handling with try/catch blocks
- Add comprehensive comment-based help

### Documentation
- Update README.md files when adding new features
- Use clear, concise language
- Include code examples where helpful
- Update any relevant diagrams or flowcharts

## 🔒 Security Considerations

- Never commit secrets, passwords, or API keys
- Follow Azure security best practices
- Use managed identities where possible
- Validate all user inputs in scripts

## 📝 Pull Request Process

1. Ensure all tests pass and templates validate successfully
2. Update documentation as needed
3. Add a clear description of what your PR accomplishes
4. Reference any related issues
5. Wait for code review and address feedback

## 🏷️ Versioning

This project follows semantic versioning (SemVer). When contributing:
- Patch releases (x.x.1) for bug fixes
- Minor releases (x.1.x) for new features
- Major releases (1.x.x) for breaking changes

## 📞 Getting Help

- Check existing issues and documentation first
- Ask questions in GitHub Discussions (if available)
- Tag maintainers in issues for urgent matters

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing to make AVD storage analytics better for everyone! 🎉
