# Quick Start

## Prerequisites

Install required dependencies:

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install ffmpeg id3v2 bc dc

# macOS (Homebrew)
brew install ffmpeg id3v2 bc dc

# Alpine
apk add ffmpeg id3v2 bc dc
```

## Basic Usage

### MP3 with CUE Sheet

```bash
# Place files in a directory:
#   book.mp3
#   book.cue
#   metadata.txt (optional)

./audiobook-optimiser.sh book.mp3
```

### M4B File

```bash
# Place file in a directory:
#   book.m4b
#   metadata.txt (optional)

./audiobook-optimiser.sh book.m4b
```

## Metadata File (Optional)

Create `metadata.txt` in the same directory:

```text
title=The Great Book
subtitle=A Subtitle
author=Jane Author
year=2023
narrator=John Narrator
series=The Series
series_order=1
description=An amazing book about things.
```

## Output

The script produces:
- `Chapter 1.mp3`, `Chapter 2.mp3`, ... (per-chapter MP3s with ID3 tags)
- `reader.txt` (narrator name for BookSonic)
- `desc.txt` (description for BookSonic)

## Configuration

Edit `audiobook-optimiser.sh` line 1 to include duration in description:

```bash
INCLUDE_DURATION_IN_DESCRIPTION=true
```

## Common Issues

| Issue | Solution |
|-------|----------|
| "command not found: ffmpeg" | Install ffmpeg |
| "command not found: id3v2" | Install id3v2 |
| No chapters extracted | Verify CUE/M4B has chapters |
| Tags not applied | Check id3v2 installation |
| Duration shows 00:00:00 | For M4B, duration calculated before splitting (known bug) |

## Next Steps

- Read [Repository Overview](./repository-overview.md) for architecture
- Read [MP3+CUE Processing Flow](./flows/mp3-cue-processing.md) for detailed flow
- Read [M4B Processing Flow](./flows/m4b-processing.md) for M4B specifics
- Read [Configuration](./configuration.md) for all options