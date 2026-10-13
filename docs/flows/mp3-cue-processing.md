# MP3 + CUE Processing Flow

## Overview

End-to-end execution flow when the input file is an MP3 with an accompanying CUE sheet.

## Preconditions

- Input file: `book.mp3` (or any `.mp3` file)
- CUE file: `book.cue` (same stem as MP3)
- Optional: `metadata.txt` in current directory
- Optional: `reader.txt` in current directory

## Execution Trace

### 1. Global Initialization (lines 1-15)

```bash
INCLUDE_DURATION_IN_DESCRIPTION=false
METADATA_FILE="./metadata.txt"
CHAPTERS_FILE="./.chapters.txt"
INPUT_FILE="${*}"                    # e.g., "book.mp3"
INPUT_DIRECTORY="."
INPUT_FILE_NAME=$(basename "${INPUT_FILE}")  # "book.mp3"
INPUT_FILE_LABEL="${INPUT_FILE_NAME%%.*}"    # "book"
INPUT_FILE_FORMAT="${INPUT_FILE_NAME##*.}"   # "mp3"
```

### 2. Function Definitions (lines 17-150)

All helper functions defined (see [components/metadata-extraction.md](../components/metadata-extraction.md) and [components/chapter-processing.md](../components/chapter-processing.md)).

### 3. Metadata Resolution (lines 152-180)

```bash
TITLE="$(getTitle)"                    # metadata.txt title OR "book"
SUBTITLE="$(getSubtitle)"              # metadata.txt subtitle OR ""
FULL_TITLE="$(getFullTitle)"           # "book" OR "book - subtitle"
AUTHOR="$(getMetadata author)"         # metadata.txt author OR ""
YEAR="$(getMetadata year)"             # metadata.txt year OR ""
DURATION="$(getDuration)"              # Sum of all .mp3 files via ffprobe
NARRATOR_NAME="$(getNarrator)"         # metadata.txt narrator OR reader.txt OR ""
SERIES_NAME="$(getMetadata series)"    # metadata.txt series OR ""
SERIES_ORDER="$(getMetadata series_order)" # metadata.txt series_order OR ""
DESCRIPTION="$(getDescription)"        # metadata.txt description OR generated
FIRST_CHAPTER_NUMBER=1                 # Default
# If *.mp3 files exist, detect first chapter number from filenames
```

### 4. CUE Processing Branch (lines 182-200)

```bash
if [ "${INPUT_FILE_FORMAT}" == "mp3" ]; then
    CUE_FILE="${INPUT_DIRECTORY}/${INPUT_FILE_LABEL}.cue"  # "./book.cue"
    if [ -f "${CUE_FILE}" ]; then
        generate_chapters_list_from_cue "${CUE_FILE}"      # Creates .chapters.txt
        extract_chapters_from_file "${INPUT_FILE}"         # Splits book.mp3 → Chapter N.mp3
        rm "${CHAPTERS_FILE}"                              # Cleanup
    fi
fi
```

**Detailed CUE Processing**:

1. `generate_chapters_list_from_cue("book.cue")`:
   - `grep "^\s*\(TRACK\|TITLE\|INDEX\)" book.cue` → extracts relevant lines
   - `tr '\n' ' ' | sed 's/\s\s*/ /g'` → single line
   - Complex `sed` transforms to timestamp pairs
   - Writes to `.chapters.txt` (format: `HH:MM:SS HH:MM:SS` or `HH:MM:SS END`)

2. `extract_chapters_from_file("book.mp3")`:
   - Reads `.chapters.txt` line by line
   - For each line: `ffmpeg -y -i book.mp3 -ss START -to END -map 0:a:0 -c:a:0 mp3 "Chapter N.mp3"`
   - If END is "END": `ffmpeg -y -i book.mp3 -ss START -map 0:a:0 -c:a:0 mp3 "Chapter N.mp3"`

### 5. Tagging Loop (lines 212-340)

```bash
TRACK_INDEX=1
TRACKS_PROCESSED=${FIRST_CHAPTER_NUMBER}

for CHAPTER_FILE in *.mp3; do
    # Parse chapter number and title from filename
    # Apply ID3 tags via id3v2
    # Increment counters
done
```

**Per-Chapter Processing**:

For each `Chapter N.mp3` file:

1. **Parse chapter info**:
   ```bash
   CHAPTER_NUMBER=$(echo "${CHAPTER_FILE}" | sed 's/^.*Chapter\s*\([0-9]*\).*/\1/g')
   CHAPTER_TITLE=$(echo "${CHAPTER_FILE}" | sed 's/^.*Chapter\s*[0-9][0-9]*\s*\(-\s*\)*\([^\.]*\).mp3/\2/g')
   ```

2. **Normalize**:
   ```bash
   CHAPTER_NUMBER=$(echo "${CHAPTER_NUMBER}" | sed 's/^0*\([0-9]\)/\1/g')
   TRACK_NUMBER=${CHAPTER_NUMBER}
   [[ "${FIRST_CHAPTER_NUMBER}" -eq 0 ]] && TRACK_NUMBER=$((CHAPTER_NUMBER+1))
   ```

3. **Build description**:
   ```bash
   CHAPTER_DESCRIPTION="Chapter ${CHAPTER_NUMBER}"
   [ "${CHAPTER_DESCRIPTION}" != "${CHAPTER_TITLE}" ] && CHAPTER_DESCRIPTION="${CHAPTER_DESCRIPTION} - ${CHAPTER_TITLE}"
   ```

4. **Apply ID3 tags**:
   ```bash
   id3v2 \
       -A "${FULL_TITLE}" \
       --TALB "${FULL_TITLE}" \
       --TOAL "" \
       -a "${AUTHOR}" \
       --TCOM "${AUTHOR}" \
       --TPE1 "${AUTHOR}" \
       --TPE2 "${NARRATOR_NAME}" \
       --TOPE "${AUTHOR}" \
       -t "${CHAPTER_TITLE}" \
       --TIT2 "${CHAPTER_TITLE}" \
       --TIT3 "" \
       -T "${TRACK_NUMBER}" \
       --TRCK "${TRACK_INDEX}" \
       -c "${CHAPTER_DESCRIPTION}" \
       --COMM "${CHAPTER_DESCRIPTION}" \
       -y "${YEAR}" \
       --TYER "${YEAR}" \
       --TORY "" \
       --TCON "Audio Book" \
       --TLAN "eng" \
       "${CHAPTER_FILE}"
   ```

5. **Increment counters**:
   ```bash
   TRACKS_PROCESSED=$((TRACKS_PROCESSED+1))
   TRACK_INDEX=$((TRACK_INDEX+1))
   ```

### 6. BookSonic Files (lines 175-178)

```bash
[ -n "${NARRATOR_NAME}" ]    && echo "${NARRATOR_NAME}"  > "reader.txt"
[ -n "${DESCRIPTION}" ]      && echo "${DESCRIPTION}"    > "desc.txt"
```

## Postconditions

- Per-chapter MP3 files: `Chapter 1.mp3`, `Chapter 2.mp3`, ...
- Each MP3 has complete ID3 tags
- `reader.txt` created if narrator known
- `desc.txt` created if description known
- Original `book.mp3` and `book.cue` unchanged

## Data Flow Diagram

```
book.mp3 + book.cue
       │
       ▼
metadata.txt ──→ TITLE, AUTHOR, YEAR, SERIES_NAME, SERIES_ORDER, NARRATOR_NAME
reader.txt ─────→ NARRATOR_NAME (fallback)
       │
       ▼
getDuration() ──→ DURATION (sum of all .mp3 via ffprobe)
       │
       ▼
generate_chapters_list_from_cue() ──→ .chapters.txt (timestamp pairs)
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

## Error Scenarios

| Scenario | Behaviour |
|----------|-----------|
| CUE file missing | Skips chapter extraction, tags existing MP3s |
| CUE file malformed | `generate_chapters_list_from_cue` produces invalid timestamps; ffmpeg may fail silently |
| ffmpeg fails | Chapter MP3 not created; tagging loop processes whatever exists |
| id3v2 fails | Tags not applied; no error reported |
| No MP3 files | `FIRST_CHAPTER_NUMBER=1`, tagging loop processes nothing |

## Related Documentation

- [components/metadata-extraction.md](../components/metadata-extraction.md)
- [components/chapter-processing.md](../components/chapter-processing.md)
- [components/id3-tagging.md](../components/id3-tagging.md)
- [data-model.md](../data-model.md)