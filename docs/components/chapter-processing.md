# Chapter Processing Component

## Purpose

Extracts chapter timestamps from CUE or M4B files and splits the audio into per-chapter MP3 files.

## Location

`audiobook-optimiser.sh` lines 182-210 (CUE processing) and lines 212-340 (M4B processing and main loop).

## Functions

### `generate_chapters_list_from_cue(cue_file)`

**Signature**: `generate_chapters_list_from_cue(cue_file: string) → void`

**Implementation**:
```bash
function generate_chapters_list_from_cue() {
    local CUE_FILE="${1}"
    local TEMP_FILE=".tmp.txt"

    grep "^\s*\(TRACK\|TITLE\|INDEX\)" "${CUE_FILE}" | tr '\n' ' ' | sed 's/\s\s*/ /g' > "${CHAPTERS_FILE}"
    sed -i \
        -e's/TRACK [0-9]* AUDIO TITLE \"\([^\"]*\)\" INDEX [0-9]* \([0-9:]*\):[0-9][0-9]*/\2 END%NL%/g' \
        -e 's/END%NL%\s*\([0-9][0-9:]*\)/\1%NL%\1/g' \
        -e 's/%NL%/\n/g' \
        -e 's/^\s*//g' \
        "${CHAPTERS_FILE}"

    local TIMESTAMPS_COUNT=0
    TIMESTAMPS_COUNT=$(wc -l "${CHAPTERS_FILE}" | awk '{print $1}')
    [ -f "${TEMP_FILE}" ] && rm "${TEMP_FILE}"

    for (( INDEX=1; INDEX<=TIMESTAMPS_COUNT; INDEX++ )); do
        TIMESTAMP=$(head -n "${INDEX}" "${CHAPTERS_FILE}" | tail -n 1)

        TIMESTAMP_START=$(awk -F" " '{print $1}' <<< "${TIMESTAMP}")
        TIMESTAMP_END=$(awk -F" " '{print $2}' <<< "${TIMESTAMP}")

        [ ${TIMESTAMP_START} == "END" ] && TIMESTAMP_START="00:00:00"
        [ ${TIMESTAMP_START} == "00:00:00" ] && TIMESTAMP_START="00:${TIMESTAMP_START}"
        [ ${TIMESTAMP_START} == "00:00:00" ] && TIMESTAMP_START=$(sed 's/^\([0-9]\):/0\1:/g' <<< "${TIMESTAMP_START}")
        [ ${TIMESTAMP_START} == "00:00:00" ] && TIMESTAMP_START=$(sed 's/^\([0-9]:[0-9]\)$/\1:0/g' <<< "${TIMESTAMP_START}")

        [ ${TIMESTAMP_END} == "END" ] && TIMESTAMP_END="23:59:59"
        [ ${TIMESTAMP_END} == "00:00:00" ] && TIMESTAMP_END="00:${TIMESTAMP_END}"
        [ ${TIMESTAMP_END} == "00:00:00" ] && TIMESTAMP_END=$(sed 's/^\([0-9]\):/0\1:/g' <<< "${TIMESTAMP_END}")
        [ ${TIMESTAMP_END} == "00:00:00" ] && TIMESTAMP_END=$(sed 's/^\([0-9]:[0-9]\)$/\1:0/g' <<< "${TIMESTAMP_END}")

        echo "${TIMESTAMP_START} ${TIMESTAMP_END}" >> "${TEMP_FILE}"
    done

    mv "${TEMP_FILE}" "${CHAPTERS_FILE}"
}
```

**Behaviour**:
- Parses CUE file TRACK/TITLE/INDEX lines
- Extracts timestamp pairs (start/end) with formatting
- Handles "END" markers (start=00:00:00, end=23:59:59)
- Writes formatted timestamps to `.chapters.txt` (one per line)

### `generate_chapters_list_from_m4b(m4b_file)`

**Signature**: `generate_chapters_list_from_m4b(m4b_file: string) → void`

**Implementation**:
```bash
function generate_chapters_list_from_m4b() {
    local M4B_FILE="${1}"
    local TEMP_FILE=".tmp.txt"

    ffmpeg -i "${M4B_FILE}" 2> "${TEMP_FILE}"
    grep "Chapter " "${TEMP_FILE}" | grep "start" | grep "end" | \
        sed 's/^\s*Chapter \#[0-9][0-9]*:\([0-9]*\): start \([0-9\.]*\), end \([0-9\.]*\).*$/\2 \3/g' \
        > "${CHAPTERS_FILE}"

    rm "${TEMP_FILE}"
}
```

**Behaviour**:
- Uses ffmpeg to extract chapter information from M4B file
- Filters lines containing "Chapter", "start", "end"
- Extracts start and end timestamps (floats)
- Writes formatted timestamps to `.chapters.txt`

### `extract_chapters_from_file(source_file)`

**Signature**: `extract_chapters_from_file(source_file: string) → void`

**Implementation**:
```bash
function extract_chapters_from_file() {
    local FILE_TO_EXTRACT="${1}"

    local TIMESTAMP=""
    local TIMESTAMP_START=""
    local TIMESTAMP_END=""
    local TIMESTAMPS_COUNT=0

    TIMESTAMPS_COUNT=$(wc -l "${CHAPTERS_FILE}" | awk '{print $1}')

    local CHAPTER_NR=0
    local CHAPTER_PREFIX=""
    local CHAPTER_FILE=""

    for (( INDEX=1; INDEX<=TIMESTAMPS_COUNT; INDEX++ )); do
        TIMESTAMP=$(head -n "${INDEX}" "${CHAPTERS_FILE}" | tail -n 1)

        TIMESTAMP_START=$(echo "${TIMESTAMP}" | awk -F" " '{print $1}')
        TIMESTAMP_END=$(echo "${TIMESTAMP}" | awk -F" " '{print $2}')

        CHAPTER_NR=${INDEX} #$((INDEX-1))

        [ ${CHAPTER_NR} -lt 1 ] && continue

        if [ ${CHAPTER_NR} -lt 10 ] && [ ${TIMESTAMPS_COUNT} -ge 10 ]; then
            CHAPTER_NR_PREFIX="0"
        else
            CHAPTER_NR_PREFIX=""
        fi

        CHAPTER_FILE="Chapter ${CHAPTER_NR_PREFIX}${CHAPTER_NR}.mp3"

        echo "Extracting chapter ${CHAPTER_NR} of ${TIMESTAMPS_COUNT} (${TIMESTAMP_START} -> ${TIMESTAMP_END}) into '${CHAPTER_FILE}'..."
        if [ "${TIMESTAMP_END}" == "END" ]; then
            ffmpeg -y -i "${FILE_TO_EXTRACT}" -ss "${TIMESTAMP_START}" -map 0:a:0 -c:a:0 mp3 "${CHAPTER_FILE}" 2>/dev/null
        else
            ffmpeg -y -i "${FILE_TO_EXTRACT}" -ss "${TIMESTAMP_START}" -to "${TIMESTAMP_END}" -map 0:a:0 -c:a:0 mp3 "${CHAPTER_FILE}" 2>/dev/null
        fi
    done
}
```

**Behaviour**:
- Reads chapter timestamps from `.chapters.txt`
- For each timestamp pair:
  - Parses start and end times
  - Handles "END" marker (full range)
  - Formats timestamps to HH:MM:SS with leading zeros
  - Calls ffmpeg to split audio at chapter boundaries
  - Outputs chapter MP3 files with naming convention `Chapter N.mp3` or `Chapter N (prefix).mp3`

## Data Flow

```
CUE file ──→ generate_chapters_list_from_cue() ──→ .chapters.txt
M4B file ──→ generate_chapters_list_from_m4b() ──→ .chapters.txt
.chapters.txt ──→ extract_chapters_from_file() ──→ Chapter MP3 files
```

## Control Flow

1. **CUE processing** (lines 182-200):
   - Check if CUE file exists
   - Call `generate_chapters_list_from_cue` if CUE exists
   - Call `extract_chapters_from_file` on input file
   - Clean up `.chapters.txt`

2. **M4B processing** (lines 202-210):
   - Call `generate_chapters_list_from_m4b` on input file
   - Call `extract_chapters_from_file` on input file
   - Clean up `.chapters.txt`

3. **Tagging loop** (lines 212-340):
   - Iterate all MP3 files in directory
   - For each file, determine chapter number and title
   - Apply ID3 tags using `id3v2`
   - Increment counters

## State Management

- **Global variables**: `CHAPTERS_FILE`, `TRACK_INDEX`, `TRACKS_PROCESSED`, `FIRST_CHAPTER_NUMBER`
- **Temporary files**: `.chapters.txt`, `.tmp.txt`
- **Output files**: Per-chapter MP3 files, `reader.txt`, `desc.txt`

## Invariants

- `.chapters.txt` always contains valid timestamp pairs (start/end or END)
- Chapter numbering is sequential and starts at 1
- All chapter MP3 files are created in current directory
- `extract_chapters_from_file` processes all chapters in order

## Error Handling

- No explicit error checking for ffmpeg/id3v2 failures
- Assumes CUE/M4B files are well-formed
- Assumes audio files are in current directory
- Assumes ffmpeg supports -ss and -to options

## Testing Considerations

- Test with CUE file containing multiple chapters
- Test with M4B file containing chapters
- Test with malformed CUE file (missing TRACK lines)
- Test with missing chapter timestamps
- Test with non-existent input file
- Verify ffmpeg command construction
- Verify chapter numbering logic