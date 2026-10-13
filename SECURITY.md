# Security Policy

This document describes the security policy for `audiobook-optimiser`, a self-hosted Bash script for local audiobook processing. The script has no network dependencies, external services, or data transmission capabilities.

## 📑 Table of Contents
- [🛡️ Supported Versions](#-supported-versions)
- [🚨 Reporting a Vulnerability](#-reporting-a-vulnerability)
- [📌 Scope](#-scope)
- [📢 Disclosure Policy](#-disclosure-policy)

## 🛡️ Supported Versions

Use this table to indicate which project versions currently receive security maintenance.

| Version | Distribution Channel | Supported |
|---------|--------------------|-----------|
| Latest version | GitHub Repository (main branch) | ✅ |
| Latest version | GitHub Releases | ✅ |
| Preceding versions | Any distribution channel | ❌ |

The project is a single-file Bash script with no formal versioning scheme. Only the current main branch and tagged releases on GitHub receive security attention.

## 🚨 Reporting a Vulnerability

Please do not disclose suspected vulnerabilities publicly before maintainers have had an opportunity to validate and remediate them.

To report a vulnerability:
- [GitHub Security Advisories](https://github.com/horatiu/audiobook-optimiser/security/advisories)
- Contact the maintainers directly via GitHub Issues

## 📌 Scope

The subsequent report categories are in scope for this repository:
- Arbitrary code execution via crafted input files (CUE, M4B, metadata.txt)
- Command injection through filename or metadata handling
- Path traversal via input file arguments
- Denial of service via resource exhaustion (large files, many chapters)

The subsequent categories are out of scope unless explicitly stated to the contrary:
- Vulnerabilities in external dependencies (ffmpeg, id3v2, bc, dc, coreutils) — report upstream
- Issues requiring network access (the script has no network capabilities)
- Data exfiltration (the script transmits no data)
- Authentication/authorisation bypass (no authentication exists)
- Cryptographic weaknesses (no cryptography is used)

## 📢 Disclosure Policy

This project follows coordinated disclosure:
1. Vulnerabilities are investigated privately.
2. A remediation plan is prepared and validated.
3. Public disclosure is published after a fix, mitigation, or agreed risk decision is available.
4. Credit is attributed in accordance with reporter preference and project policy.