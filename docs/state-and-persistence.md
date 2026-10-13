# State and Persistence

## State Management

The script is **stateless** between runs. No persistent state is maintained.

### Runtime State (In-Memory)

| Variable | Scope | Lifetime | Purpose |
|----------|-------|----------|---------|
| `INCLUDE_DURATION_IN_DESCRIPTION` | Global | Script run | Config flag |
| `METADATA_FILE` | Global | Script run | Config path |
| `CHAPTERS_FILE` | Global | Script run | Temp file path |
| `INPUT_FILE` | Global | Script run | Input file path |
| `INPUT_DIRECTORY` | Global | Script run | Working directory |
| `INPUT_FILE_NAME` | Global | Script run | Input filename |
| `INPUT_FILE_LABEL` | Global | Script run | Input stem |
| `INPUT_FILE_FORMAT` | Global | Script run | Input extension |
| `TITLE`, `SUBTITLE`, `FULL_TITLE` | Global | Script run | Resolved metadata |
| `AUTHOR`, `YEAR`, `NARRATOR_NAME` | Global | Script run | Resolved metadata |
| `SERIES_NAME`, `SERIES_ORDER` | Global | Script run | Resolved metadata |
| `DESCRIPTION`, `DURATION` | Global | Script run | Resolved metadata |
| `FIRST_CHAPTER_NUMBER` | Global | Script run | Chapter start |
| `TRACK_INDEX`, `TRACKS_PROCESSED` | Global | Script run | Tagging counters |

### Persistent State (Filesystem)

#### Input Files (User-Provided)

| File | Format | Required | Description |
|------|--------|----------|-------------|
| `metadata.txt` | `key=value` | No | Book metadata |
| `reader.txt` | Plain text | No | Narrator fallback |
| `book.mp3` | Audio | MP3 mode | Source audio |
| `book.cue` | CUE sheet | MP3 mode | Chapter timestamps |
| `book.m4b` | Audio | M4B mode | Source audio + chapters |

#### Output Files (Script-Generated)

| File | Format | Description |
|------|--------|-------------|
| `Chapter N.mp3` | MP3 audio | Per-chapter audio with ID3 tags |
| `reader.txt` | Plain text | Narrator name (BookSonic) |
| `desc.txt` | Plain text | Description (BookSonic) |

#### Temporary Files (Script-Generated, Cleaned Up)

| File | Format | Lifetime | Description |
|------|--------|----------|-------------|
| `.chapters.txt` | Timestamps | During chapter processing | Chapter start/end pairs |
| `.tmp.txt` | Various | During chapter processing | Intermediate processing |

## Persistence Patterns

### Write Patterns

1. **Chapter MP3s**: Created once per chapter, overwritten on re-run
2. **reader.txt/desc.txt**: Overwritten each run (not appended)
3. **Temporary files**: Created, used, deleted within same run

### Read Patterns

1. **metadata.txt**: Read multiple times via `getMetadata()`
2. **reader.txt**: Read once via `getNarrator()`
3. **CUE file**: Read once via `generate_chapters_list_from_cue()`
4. **M4B file**: Read once via `generate_chapters_list_from_m4b()`
5. **Input audio**: Read multiple times (ffprobe + ffmpeg per chapter)

## State Transitions

```
Initial State
    │
    ▼
Read metadata.txt, reader.txt
    │
    ▼
Compute metadata variables
    │
    ▼
[MP3+CUE] Read CUE → .chapters.txt → Split audio → Chapter MP3s
[M4B]     Read M4B → .chapters.txt → Split audio → Chapter MP3s
    │
    ▼
Tag all MP3s in directory
    │
    ▼
Write reader.txt, desc.txt
    │
    ▼
Cleanup temp files
    │
    ▼
Final State
```

## Idempotency

**Partially idempotent**:
- Re-running on same directory overwrites chapter MP3s and tags
- `reader.txt` and `desc.txt` overwritten
- Temporary files recreated and cleaned
- **Non-idempotent**: If new MP3s added to directory, they get tagged too

## Migration

No migration needed. No schema versioning. Output format stable.

## Backup/Recovery

No built-in backup. User responsible for:
- Backing up source files (MP3/M4B/CUE/metadata.txt)
- Re-running script to regenerate outputs

## Cache

No caching. All computation repeated each run.