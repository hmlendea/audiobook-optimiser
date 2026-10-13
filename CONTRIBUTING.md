# Contributing to audiobook-optimiser

This document covers the guidelines and processes for contributing to this project, including how to report issues, suggest enhancements, submit code changes, and follow project standards.

## 📑 Table of Contents
- [🤝 How to Contribute](#-how-to-contribute)
- [📋 Code of Conduct](#-code-of-conduct)
- [🔒 Security](#-security)
- [📄 License](#-license)
- [❓ Getting Help](#-getting-help)

## 🤝 How to Contribute

### Reporting Issues

- Search existing issues first.
- Use the issue templates if available.
- Provide clear reproduction steps.
- Include environment details (Bash version, ffmpeg version, OS).

### Suggesting Enhancements

- Check the roadmap and existing discussions.
- Explain the use case and expected behavior.
- Consider implementation complexity.

### Code Contributions

#### Prerequisites

- Bash 4.0+
- ffmpeg and ffprobe
- id3v2
- bc and dc
- GNU coreutils (awk, sed, grep, sort)

#### Development Setup

```bash
# Clone the repository
git clone https://github.com/horatiu/audiobook-optimiser.git
cd audiobook-optimiser

# No installation required; make script executable
chmod +x audiobook-optimiser.sh
```

#### Making Changes

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes.
4. Test manually with sample audiobook files.
5. Commit with clear and descriptive messages.
6. Push to your fork.
7. Open a Pull Request.

#### Pull Request Guidelines

- Target the `main` branch.
- Keep PRs focused and atomic.
- Update documentation if applicable.
- Ensure the script runs without errors on test inputs.

### Code Style

Follow the project's coding standards:
- Use 4-space indentation
- Use descriptive function and variable names
- Add comments for non-obvious logic
- Run `shellcheck audiobook-optimiser.sh` before committing (if shellcheck is available)

### Testing

No automated test suite exists. Manual verification:

```bash
# Place test audiobook file (MP3 or M4B), metadata.txt, and optionally reader.txt and CUE file in a directory
./audiobook-optimiser.sh <audiobook_file>
# Verify chapter MP3 files are created with correct ID3 tags
# Verify reader.txt and desc.txt are created if applicable
```

### Documentation

- Update relevant docs for changes (README.md, ARCHITECTURE.md, docs/ files)
- Follow the documentation style guide
- Preview changes locally if possible

## 📋 Code of Conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).

## 🔒 Security

Report security vulnerabilities per the [Security Policy](SECURITY.md).

## 📄 License

By contributing, you agree that your contributions will be licensed under the [GNU General Public License v3.0](LICENSE).

## ❓ Getting Help

- Check existing discussions and documentation first.
- Open a GitHub Issue for questions or problems.