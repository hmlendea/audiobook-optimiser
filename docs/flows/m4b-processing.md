# M4B Processing Flow

## Overview

End-to-end execution flow when the input file is an M4B audiobook.

## Preconditions

- Input file: `book.m4b` (or any `.m4b` file)
- Optional: `metadata.txt` in current directory
- Optional: `reader.txt` in current directory

## Execution Trace

### 1. Global Initialization (lines 1-15)

Same as [MP3+CUE Processing Flow](./mp3-cue-processing.md).

### 2. Function Definitions (lines 17-150)

Same as [MP3+CUE Processing Flow](./mp3-cue-processing.md).

### 3. Metadata Resolution (lines 152-180)

Same as [MP3+CUE Processing Flow](./mp3-cue-processing.md).

### 4. M4B Processing Branch (lines 202-210)

```bash
elif [ "${INPUT_FILE_FORMAT}" == "m4b" ]; then
    generate_chapters_list_from_m4b "${INPUT_FILE}"      # Creates .chapters.txt
    extract_chapters_from_file "${INPUT_FILE}"           # Splits book.m4b → Chapter N.mp3
    rm "${CHAPTERS_FILE}"                                # Cleanup
fi
```

**Detailed M4B Processing**:

1. `generate_chapters_list_from_m4b("book.m4b")`:
   - `ffmpeg -i book.m4b 2> .tmp.txt` → captures ffmpeg stderr
   - `grep "Chapter " .tmp.txt | grep "start" | grep "end"` → filters chapter lines
   - `sed 's/^\s*Chapter \#[0-9][0-9]*:\([0-9]*\): start \([0-9\.]*\), end \([0-9\.]*\).*$/\2 \3/g'` → extracts start/end floats
   - Writes to `.chapters.txt` (format: `start_seconds end_seconds`)

2. `extract_chapters_from_file("book.m4b")`:
   - Reads `.chapters.txt` line by line (each line: `start end`)
   - For each line: `ffmpeg -y -i book.m4b -ss START -to END -map 0:a:0 -c:a:0 mp3 "Chapter N.mp3"`
   - Note: The M4B flow does not handle "END" markers (unlike CUE). If the last chapter has no end timestamp, it will be missing from the ffmpeg output.

### 5. Tagging Loop (lines 212-340)

Same as [MP3+CUE Processing Flow](./mp3-cue-processing.md).

### 6. BookSonic Files (lines 175-178)

Same as [MP3+CUE Processing Flow](./mp3-cue-processing.md).

## Postconditions

- Per-chapter MP3 files: `Chapter 1.mp3`, `Chapter 2.mp3`, ...
- Each MP3 has complete ID3 tags
- `reader.txt` created if narrator known
- `desc.txt` created if description known
- Original `book.m4b` unchanged

## Data Flow Diagram

```
book.m4b
       │
       ▼
metadata.txt ──→ TITLE, AUTHOR, YEAR, SERIES_NAME, SERIES_ORDER, NARRATOR_NAME
reader.txt ─────→ NARRATOR_NAME (fallback)
       │
       ▼
getDuration() ──→ DURATION (sum of all .mp3 via ffprobe) [Note: This runs before splitting, so it will be 0 if no .mp3 exist yet!]
       │
       ▼
generate_chapters_list_from_m4b() ──→ .chapters.txt (timestamp pairs in seconds)
       │
       ▼
extract_chapters_from_file() ──→ Chapter 1.mp3, Chapter 2.mp3, ...
       │
       ▼
Tagging loop ──→ ID3 tags applied to each chapter
       │
       ▼
reader.txt, desc.txt (BookSonic compatibility)
```

## Important Note on Duration Calculation

The `getDuration()` function is called **before** the M4B is split into MP3s. It sums the duration of all existing `.mp3` files in the directory. At the point of the M4B processing branch, there are no `.mp3` files yet (unless from a previous run). Therefore, `DURATION` will be empty or 0, and the duration will not be included in the description even if `INCLUDE_DURATION_IN_DESCRIPTION=true`.

This is a bug in the script: the duration should be calculated from the source file (M4B) or after splitting.

## Error Scenarios

| Scenario | Behaviour |
|----------|-----------|
| M4B missing chapters | `generate_chapters_list_from_m4b` produces empty `.chapters.txt`; no chapters extracted |
| ffmpeg fails to extract chapters | `.chapters.txt` empty or malformed; extraction may produce zero or incorrect chapters |
| ffmpeg fails during splitting | Chapter MP3 not created; tagging loop processes whatever exists |
| id3v2 fails | Tags not applied; no error reported |
| No MP3 files after splitting | Tagging loop processes nothing |

## Related Documentation

- [components/metadata-extraction.md](../components/metadata-extraction.md)
- [components/chapter-processing.md](../components/chapter-processing.md)
- [components/id3-tagging.md](../components/id3-tagging.md)
- [data-model.md](../data-model.md)
- [flows/mp3-cue-processing.md](./mp3-cue-processing.md) (for comparison)