# Architecture

## Overview

`audiobook-optimiser` is a single-file Bash script (`audiobook-optimiser.sh`) that implements a linear pipeline for audiobook processing. It has no formal modular architecture but can be understood as a sequence of functional stages.

## Pipeline Stages

```
Input Detection
    ↓
Metadata Extraction (metadata.txt + fallbacks)
    ↓
Duration Calculation (ffprobe)
    ↓
Chapter Extraction (CUE → timestamps OR M4B → timestamps)
    ↓
Audio Splitting (ffmpeg per chapter)
    ↓
ID3 Tagging (id3v2 per chapter file)
    ↓
Cleanup (temporary files)
```

## Component Boundaries

| Stage | Responsibility | Key Functions | External Tools |
|-------|---------------|---------------|----------------|
| Input Detection | Identify input file, format, directory | Global variable init | `basename`, `ls` |
| Metadata Extraction | Parse `metadata.txt`, fallback to `reader.txt` | `getMetadata`, `getTitle`, `getSubtitle`, `getFullTitle`, `getNarrator` | `grep`, `awk`, `cat` |
| Duration Calculation | Sum duration of all MP3 files | `getDuration` | `ffprobe`, `bc`, `dc`, `awk` |
| Chapter Extraction (CUE) | Parse CUE file to timestamp pairs | `generate_chapters_list_from_cue` | `grep`, `sed`, `awk` |
| Chapter Extraction (M4B) | Extract chapter timestamps from M4B | `generate_chapters_list_from_m4b` | `ffmpeg`, `grep`, `sed` |
| Audio Splitting | Split source audio into chapter MP3s | `extract_chapters_from_file` | `ffmpeg` |
| ID3 Tagging | Apply comprehensive ID3 tags | Main loop (lines 270-340) | `id3v2` |
| Cleanup | Remove temporary files | Implicit in functions | `rm` |

## Data Flow

```
metadata.txt ──┐
               ├──→ Metadata variables (TITLE, AUTHOR, YEAR, SERIES_NAME, SERIES_ORDER, NARRATOR_NAME)
reader.txt ────┘           │
                           ↓
                    DESCRIPTION generation
                           │
CUE file ──────────────────┼──→ Chapter timestamps (start/end pairs)
M4B file ──────────────────┘           │
                                       ↓
                              ffmpeg splits audio
                                       │
                              Chapter MP3 files ──→ id3v2 tags applied
```

## Control Flow

The script executes top-to-bottom with conditional branching on input format:

1. **Global initialization** (lines 1-15): Set constants, derive input file properties
2. **Function definitions** (lines 17-150): All helper functions defined
3. **Metadata resolution** (lines 152-180): Populate global metadata variables
4. **Format-specific processing** (lines 182-210): CUE or M4B chapter extraction + splitting
5. **Tagging loop** (lines 212-340): Iterate all MP3 files, apply ID3 tags

## State Management

- **Global variables**: All metadata and configuration stored in global shell variables
- **Temporary files**: `.chapters.txt`, `.tmp.txt` used during chapter processing
- **Output files**: Per-chapter MP3 files, `reader.txt`, `desc.txt` (BookSonic compatibility)

## Integration Points

- **AudioBookshelf**: Expects standard ID3 tags (TIT2, TALB, TPE1, TPE2, TRCK, TYER, TCON, COMM)
- **BookSonic**: Additionally reads `reader.txt` (narrator) and `desc.txt` (description) files
- **File system**: Reads from current directory, writes chapter MP3s to current directory

## Concurrency Model

Single-threaded, sequential execution. No parallelism. Each chapter processed sequentially in the tagging loop.

## Error Handling

Minimal. Relies on external tool exit codes. No explicit error checking for:
- Missing input files
- Failed ffmpeg/ffprobe/id3v2 invocations
- Malformed CUE/M4B files
- Missing dependencies

See [error-handling.md](./error-handling.md) for details.