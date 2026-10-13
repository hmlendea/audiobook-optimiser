# Privacy and Personal Data

This document describes how `audiobook-optimiser` handles personal data. It covers the script behaviour and verified integrations described below. The software is self-hosted; the instance operator controls their instance's configuration, local storage, logs, backups, access controls, retention, and request handling.

**Information reviewed:** 2026-10-13

## Table of Contents

- [What This Document Covers](#what-this-document-covers)
- [Self-Hosted Deployments](#self-hosted-deployments)
- [Data We Handle](#data-we-handle)
- [Processing and Use](#processing-and-use)
- [Storage, Retention, and Deletion](#storage-retention-and-deletion)
- [External Processing and Integrations](#external-processing-and-integrations)
- [Document Changes](#document-changes)
- [Contact](#contact)

## What This Document Covers

This document describes how `audiobook-optimiser` at https://github.com/horatiu/audiobook-optimiser handles personal data. It covers the script behaviour and verified integrations described below. Where the software is self-hosted, the instance operator may have separate responsibilities described below.

## Self-Hosted Deployments

`audiobook-optimiser` is a self-hosted Bash script. The instance operator (the person running the script) controls all aspects of the deployment: configuration, local storage, logs, backups, access controls, retention, and request handling. The project maintainers do not operate any instance and do not receive any data from self-hosted deployments.

No data is sent from a self-hosted instance to project maintainers or external services. There is no telemetry, update checks, crash reports, email, authentication, reverse-proxy, object-storage, or monitoring integrations built into the script.

## Data We Handle

### Data Provided to the Application

- Audiobook metadata provided via `metadata.txt` (title, subtitle, author, year, narrator, series name, series order, description) — all optional
- Narrator name provided via `reader.txt` (optional fallback)
- Audio files (MP3, M4B) and CUE sheets provided by the operator

### Data Generated or Collected by the Application

- No personal data is generated or collected automatically by the application
- The script computes total audio duration from local files using `ffprobe`
- The script extracts chapter timestamps from local CUE or M4B files

### Data Received from Integrations

- No personal data is received from integrations or third parties

## Processing and Use

The application processes the data described above for these verified functions:
- Reading metadata from `metadata.txt` and `reader.txt` — metadata fields (title, author, narrator, etc.)
- Extracting chapter timestamps from CUE sheets or M4B files — chapter timing data
- Splitting audio files into per-chapter MP3s using `ffmpeg` — audio content
- Writing ID3 tags to chapter MP3s using `id3v2` — metadata fields (title, author, narrator, year, genre, language)
- Writing `reader.txt` and `desc.txt` for BookSonic compatibility — narrator name and description

## Storage, Retention, and Deletion

All data is stored locally on the instance operator's filesystem:

| Data Category | Storage Location | Retention | Deletion Control |
|---------------|------------------|-----------|------------------|
| Input audio files (MP3, M4B) | Operator's working directory | Until operator deletes | Operator controls |
| Input CUE sheets | Operator's working directory | Until operator deletes | Operator controls |
| `metadata.txt` | Operator's working directory | Until operator deletes | Operator controls |
| `reader.txt` (input) | Operator's working directory | Until operator deletes | Operator controls |
| Chapter MP3 output files | Operator's working directory | Until operator deletes | Operator controls |
| `reader.txt` (output) | Operator's working directory | Until operator deletes | Operator controls |
| `desc.txt` (output) | Operator's working directory | Until operator deletes | Operator controls |
| Temporary files (`.chapters.txt`, `.tmp.txt`) | Operator's working directory | During script execution only | Automatically deleted after each run |

The project maintainers do not control storage, deletion, or backups. The instance operator has full control over all data.

## External Processing and Integrations

The script has no built-in external data transfer. It invokes local command-line tools only:

| Service or integration | Purpose | Data involved | Configuration or documentation |
|-----------------------|---------|---------------|--------------------------------|
| `ffmpeg` / `ffprobe` | Audio processing, duration extraction, chapter extraction | Audio file content, chapter timestamps | https://ffmpeg.org/ |
| `id3v2` | ID3 tag writing | Metadata fields (title, author, narrator, year, genre, language) | https://id3v2.sourceforge.net/ |
| `bc` / `dc` | Duration arithmetic and formatting | Numeric duration values | Standard POSIX utilities |
| GNU coreutils (`awk`, `sed`, `grep`, `sort`, etc.) | Text processing, parsing | Metadata text, CUE file content, filenames | Standard POSIX utilities |

No data is transmitted to external services. All processing occurs locally.

## Document Changes

Update this document when application data flows, storage, integrations, or deployment responsibilities change. The current version is published at https://github.com/horatiu/audiobook-optimiser/blob/main/PRIVACY.md.

## Contact

For questions about application data handling, contact the project maintainers via GitHub issues at https://github.com/horatiu/audiobook-optimiser/issues. For a self-hosted instance, contact the instance operator. Do not send passwords, access tokens, or other secrets.