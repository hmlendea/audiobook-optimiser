# Repository Overview

## Purpose

`audiobook-optimiser` is a Bash script that automates the preparation of audiobook files for self-hosted audiobook servers (AudioBookshelf, BookSonic). It handles:

1. **Metadata extraction** from a simple text configuration file
2. **Chapter extraction** from CUE sheets (for MP3) or embedded chapters (for M4B)
3. **Audio splitting** into per-chapter MP3 files using ffmpeg
4. **ID3 tagging** with comprehensive metadata for server compatibility
5. **BookSonic compatibility files** (`reader.txt`, `desc.txt`)

## Scope

### In Scope

- Single-file Bash script (`audiobook-optimiser.sh`)
- MP3 + CUE sheet input format
- M4B input format
- Metadata via `metadata.txt` key=value file
- Output: per-chapter MP3s with ID3v2 tags
- BookSonic auxiliary files

### Out of Scope

- GUI or web interface
- Batch processing of multiple books
- Format conversion beyond MP3 output
- Cloud/service integration
- Database or persistent state
- Parallel processing
- Automated testing

## Entry Points

### Primary Entry Point

```bash
./audiobook-optimiser.sh <input-file>
```

- `<input-file>`: Path to MP3 or M4B file
- Script must be executable (`chmod +x audiobook-optimiser.sh`)
- Runs in current directory

### Configuration Entry Point

`metadata.txt` in current directory (optional but recommended)

## Repository Structure

```
audiobook-optimiser/
├── audiobook-optimiser.sh    # Main script (single file)
├── README.md                 # Brief project description
├── LICENSE                   # GNU GPL v3
└── docs/                     # This documentation
    ├── INDEX.md
    ├── architecture.md
    ├── configuration.md
    ├── data-model.md
    ├── dependencies.md
    ├── error-handling.md
    ├── invariants.md
    ├── logging.md
    ├── quick-start.md
    ├── repository-overview.md
    ├── repository-structure.md
    ├── components/
    │   ├── metadata-extraction.md
    │   ├── chapter-processing.md
    │   ├── id3-tagging.md
    │   └── file-discovery.md
    └── flows/
        ├── mp3-cue-processing.md
        └── m4b-processing.md
```

## Key Design Decisions

1. **Single-file script**: No modules, no external libraries, easy to deploy
2. **File-based configuration**: Simple `key=value` text file, no complex formats
3. **External tool dependency**: Leverages ffmpeg, id3v2, bc, dc for heavy lifting
4. **Linear pipeline**: No branching logic except format detection
5. **BookSonic compatibility**: Extra files for legacy server support

## Target Audience

- Self-hosted audiobook server administrators
- Users converting personal audiobook collections
- Automation scripts for bulk processing

## Supported Servers

| Server | Compatibility | Notes |
|--------|---------------|-------|
| AudioBookshelf | Full | Standard ID3 tags |
| BookSonic | Full | ID3 tags + reader.txt + desc.txt |
| Plex | Partial | May need additional tags |
| Emby/Jellyfin | Partial | May need additional tags |

## Limitations

1. **Single book per run**: Cannot batch process
2. **No validation**: Assumes well-formed inputs
3. **No error recovery**: Fails silently on tool errors
4. **GNU tool dependencies**: May not work on BSD/macOS without GNU coreutils
5. **Duration bug for M4B**: Calculated before splitting
6. **Multiple input args bug**: Breaks filename parsing
7. **No tests**: No automated test suite