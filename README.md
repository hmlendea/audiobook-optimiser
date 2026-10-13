[![License](https://img.shields.io/github/license/horatiu/audiobook-optimiser)](https://github.com/horatiu/audiobook-optimiser/blob/main/LICENSE)

# audiobook-optimiser

A self-hosted Bash script that processes audiobook files (MP3 or M4B) with accompanying metadata and chapter information to produce tagged chapter MP3 files for audiobook servers like AudioBookshelf and BookSonic.

## 📑 Table of Contents
- [✨ Capabilities](#-capabilities)
- [🎯 Use Cases](#-use-cases)
- [🚀 Usage](#-usage)
- [⚠️ Known Limitations](#-known-limitations)
- [🖥️ System Requirements](#-system-requirements)
- [📦 Installation](#-installation)
- [⚙️ Configuration](#-configuration)
- [🛡️ Privacy and Data](#-privacy-and-data)
- [🛠️ Development](#-development)
- [🗂️ Project Structure](#-project-structure)
- [🏗️ Architecture](#-architecture)
- [📚 Documentation](#-documentation)
- [🤝 Contributing](#-contributing)
- [🔒 Security](#-security)
- [💝 Project Engagement](#-project-engagement)
- [📄 License](#-license)

## ✨ Capabilities
- Processes MP3 audiobooks with CUE sheets or M4B files with embedded chapters
- Extracts metadata from `metadata.txt` (title, author, year, narrator, series, description)
- Falls back to `reader.txt` for narrator name
- Calculates total audio duration from MP3 files
- Splits source audio into per-chapter MP3 files using ffmpeg
- Applies comprehensive ID3 tags (title, artist, album, year, genre, track, comment, composer, narrator)
- Generates `reader.txt` and `desc.txt` for BookSonic compatibility
- Cleans up temporary files automatically

## 🎯 Use Cases
- **Personal audiobook library management:** Convert single-file audiobooks with chapters into tagged chapter files for AudioBookshelf or BookSonic
- **Metadata enrichment:** Apply consistent, complete ID3 tags across chapter files from a simple text metadata file
- **Format conversion:** Convert M4B audiobooks to MP3 chapters with proper tagging

## 🚀 Usage

Place the following files in a directory:
- Audiobook file: `book.mp3` (with `book.cue`) or `book.m4b`
- `metadata.txt` with metadata fields (optional but recommended)
- `reader.txt` with narrator name (optional fallback)

```bash
./audiobook-optimiser.sh book.mp3
# or
./audiobook-optimiser.sh book.m4b
```

The script will produce:
- `Chapter 01.mp3`, `Chapter 02.mp3`, ... (tagged chapter files)
- `reader.txt` (narrator name for BookSonic)
- `desc.txt` (description for BookSonic)

### Example `metadata.txt`
```text
title=The Great Adventure
subtitle=A Journey Through Time
author=Jane Smith
year=2023
narrator=John Doe
series=Adventure Series
series_order=1
description=An epic tale of discovery and courage.
```

## ⚠️ Known Limitations
- No automated test suite; verification is manual
- Minimal error handling; relies on external tool exit codes
- Assumes GNU coreutils extensions (e.g., `sort -h`); may not work on BSD/macOS without GNU tools
- Multiple input arguments break filename parsing (`${*}` concatenates)
- M4B duration calculated before splitting (returns 0)
- `getNarrator()` regex bug: `grep '^\s*$'` matches empty lines instead of non-empty
- No validation of malformed CUE files or corrupt audio
- Single-threaded; processes one audiobook at a time

## 🖥️ System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| OS | Linux (tested) | Linux |
| Bash | 4.0+ | 5.0+ |
| ffmpeg / ffprobe | 4.0+ | Latest stable |
| id3v2 | 0.1.12+ | Latest stable |
| bc / dc | Standard | Standard |
| GNU coreutils | Standard | Latest (for `sort -h`) |

## 📦 Installation

[![Obtain it from GitHub](https://raw.githubusercontent.com/hmlendea/readme-assets/master/badges/stores/github.png)](https://github.com/horatiu/audiobook-optimiser/releases)

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/horatiu/audiobook-optimiser.git
cd audiobook-optimiser

# Make the script executable
chmod +x audiobook-optimiser.sh

# Verify dependencies are installed
which ffmpeg ffprobe id3v2 bc dc awk sed grep sort
```

No package manager installation is available; the script is distributed as a single executable file via GitHub.

## ⚙️ Configuration

The script uses the following configuration files in the working directory:

| File | Purpose | Required |
|------|---------|----------|
| `metadata.txt` | Key=value metadata (title, author, year, narrator, series, series_order, description, subtitle) | No |
| `reader.txt` | Narrator name (fallback if not in metadata.txt) | No |
| `<audiobook>.cue` | Chapter timestamps for MP3 input | Yes (for MP3) |

Environment variable:
- `INCLUDE_DURATION_IN_DESCRIPTION` — Set to `true` to append duration to generated description (default: `false`)

## 🛡️ Privacy and Data

This project processes all data locally. No data is transmitted to external services. See [PRIVACY.md](PRIVACY.md) for details.

## 🛠️ Development

```bash
# Clone and enter the repository
git clone https://github.com/horatiu/audiobook-optimiser.git
cd audiobook-optimiser

# Make script executable
chmod +x audiobook-optimiser.sh

# Run shellcheck for style checking (optional)
shellcheck audiobook-optimiser.sh

# Test with sample files
./audiobook-optimiser.sh sample.mp3
```

## 🗂️ Project Structure

```
audiobook-optimiser/
├── audiobook-optimiser.sh    # Main script
├── LICENSE                   # GPL v3.0
├── README.md                 # This file
├── ARCHITECTURE.md           # Architecture documentation
├── SECURITY.md               # Security policy
├── CONTRIBUTING.md           # Contribution guidelines
├── PRIVACY.md                # Privacy policy
└── docs/                     # Detailed documentation
    ├── INDEX.md              # Documentation index
    ├── architecture.md       # Detailed architecture
    ├── components/           # Component references
    ├── flows/                # Processing flow traces
    ├── reference/            # Reference materials
    └── guides/               # User guides
```

## 🏗️ Architecture

See [architecture documentation](ARCHITECTURE.md) for the system context, pipeline stages, component boundaries, data flow, and deployment model.

## 📚 Documentation

The `docs/` directory contains comprehensive documentation:
- [Documentation Index](docs/INDEX.md) — Master catalogue of all docs
- [Architecture](docs/architecture.md) — Detailed architecture complementing ARCHITECTURE.md
- [Components](docs/components/) — Function signatures, behavior, data flow, invariants, error modes
- [Flows](docs/flows/) — End-to-end execution traces for MP3/CUE and M4B processing
- [Reference](docs/reference/) — Metadata schema, ID3 tag mapping, CLI reference, environment variables
- [Guides](docs/guides/) — Quick start, troubleshooting, migration, compatibility

## 🤝 Contributing

You are welcome to submit any suggestion, feedback, or modification to this project.

When doing so, please:
- Maintain cross-platform compatibility
- Submit focused pull requests that conform to the existing code style
- Maintain your branch synchronised with `main`
- Revise the documentation when functionality changes
- Raise a new [issue](https://github.com/horatiu/audiobook-optimiser/issues) for problems or suggestions

See the [contributing guidelines](./CONTRIBUTING.md) for details on how to report issues, suggest enhancements, and submit changes.

## 🔒 Security

See [SECURITY.md](SECURITY.md) for the security policy, supported versions, vulnerability reporting, and disclosure process.

## 💝 Project Engagement

Discovered a problem or have a suggestion? [Open an issue](https://github.com/horatiu/audiobook-optimiser/issues)!

If you find this project useful, consider starring ⭐️ it on GitHub!

## 📄 License

This project is being distributed under the `GNU General Public License v3.0`.
See [LICENSE](./LICENSE) for further information.