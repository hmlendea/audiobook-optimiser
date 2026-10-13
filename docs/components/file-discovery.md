# File Discovery Component

## Purpose

Detects input files, determines format, and discovers existing MP3 files for processing.

## Location

`audiobook-optimiser.sh` lines 1-15 (global initialization) and lines 182-210 (format-specific processing)

## Input File Detection

### Global Variables (lines 1-15)

```bash
INPUT_FILE="${*}"                              # All script arguments
INPUT_DIRECTORY="."                            # Current directory
INPUT_FILE_NAME=$(basename "${INPUT_FILE}")    # Filename with extension
INPUT_FILE_LABEL="${INPUT_FILE_NAME%%.*}"      # Filename stem (no extension)
INPUT_FILE_FORMAT="${INPUT_FILE_NAME##*.}"     # File extension (mp3/m4b)
```

### Behaviour

- `INPUT_FILE` takes all positional arguments (`${*}`)
- If multiple arguments provided, they are concatenated with spaces
- `basename` extracts filename from path
- Parameter expansion extracts stem and extension

### Edge Cases

| Input | `INPUT_FILE` | `INPUT_FILE_NAME` | `INPUT_FILE_LABEL` | `INPUT_FILE_FORMAT` |
|-------|--------------|-------------------|-------------------|---------------------|
| `book.mp3` | `book.mp3` | `book.mp3` | `book` | `mp3` |
| `path/to/book.mp3` | `path/to/book.mp3` | `book.mp3` | `book` | `mp3` |
| `book.m4b` | `book.m4b` | `book.m4b` | `book` | `m4b` |
| `book part1.mp3 book part2.mp3` | `book part1.mp3 book part2.mp3` | `book part1.mp3 book part2.mp3` | `book part1.mp3 book part2` | `mp3 book part2` |

**Bug**: Multiple arguments break filename parsing. The script assumes a single input file.

## Format-Specific Processing

### MP3 + CUE Branch (lines 182-200)

```bash
if [ "${INPUT_FILE_FORMAT}" == "mp3" ]; then
    CUE_FILE="${INPUT_DIRECTORY}/${INPUT_FILE_LABEL}.cue"
    if [ -f "${CUE_FILE}" ]; then
        generate_chapters_list_from_cue "${CUE_FILE}"
        extract_chapters_from_file "${INPUT_FILE}"
        rm "${CHAPTERS_FILE}"
    fi
fi
```

**Logic**:
1. Check if input format is "mp3"
2. Look for CUE file with same stem in same directory
3. If CUE exists: extract chapters and split audio
4. If CUE missing: skip chapter extraction, proceed to tagging

### M4B Branch (lines 202-210)

```bash
elif [ "${INPUT_FILE_FORMAT}" == "m4b" ]; then
    generate_chapters_list_from_m4b "${INPUT_FILE}"
    extract_chapters_from_file "${INPUT_FILE}"
    rm "${CHAPTERS_FILE}"
fi
```

**Logic**:
1. Check if input format is "m4b"
2. Extract chapters directly from M4B file
3. Split audio into chapters
3. No CUE file involved

## Existing MP3 Discovery

### First Chapter Number Detection (lines 170-174)

```bash
[ $(ls *.mp3 | wc -l) != 0 ] && FIRST_CHAPTER_NUMBER=$(ls *.mp3 | \
                                        sed 's/^.*\(Chapter\s\)*\([0-9][0-9]*\).*$/\1/g' | \
                                        sort -h | head -n 1 | \
                                        sed 's/^0*\([0-9]\)/\1/g')
[[ -z "${FIRST_CHAPTER_NUMBER}" ]] && FIRST_CHAPTER_NUMBER=1
```

**Logic**:
1. If any `.mp3` files exist in current directory
2. List all MP3 files
3. Extract chapter numbers using regex
4. Sort numerically, take first (minimum)
5. Strip leading zeros
6. Default to 1 if no match

### Tagging Loop File Iteration (line 212)

```bash
for CHAPTER_FILE in *.mp3; do
```

**Logic**:
- Iterates all `.mp3` files in current directory
- Includes both newly created chapter files and any pre-existing MP3s
- Order is filesystem-dependent (typically alphabetical)

## File Patterns

### Expected Input Patterns

| Format | Input File | Companion File | Chapter Output |
|--------|------------|----------------|----------------|
| MP3+CUE | `book.mp3` | `book.cue` | `Chapter 1.mp3`, `Chapter 2.mp3`, ... |
| M4B | `book.m4b` | (none) | `Chapter 1.mp3`, `Chapter 2.mp3`, ... |
| MP3 only | `book.mp3` | (none) | Tags existing `book.mp3` only |

### Output Files

| File | Created By | Purpose |
|------|------------|---------|
| `Chapter N.mp3` | `extract_chapters_from_file` | Per-chapter audio |
| `reader.txt` | Main script (line 175) | BookSonic narrator |
| `desc.txt` | Main script (line 176) | BookSonic description |
| `.chapters.txt` | Chapter extraction functions | Temporary timestamps |
| `.tmp.txt` | Chapter extraction functions | Temporary processing |

## Invariants

- `INPUT_FILE_FORMAT` is either "mp3" or "m4b" (no validation)
- CUE file must have same stem as MP3 file
- M4B file contains embedded chapters
- All MP3 files in directory are processed in tagging loop
- `FIRST_CHAPTER_NUMBER` ≥ 1

## Error Modes

| Condition | Behaviour |
|-----------|-----------|
| No input file provided | `INPUT_FILE=""`, `INPUT_FILE_NAME=""`, `INPUT_FILE_LABEL=""`, `INPUT_FILE_FORMAT=""` |
| Multiple input files | Concatenated; parsing breaks |
| Input file missing | `basename` still works; downstream ffmpeg fails |
| CUE file missing (MP3) | Chapter extraction skipped; existing MP3s tagged |
| No MP3 files in directory | `FIRST_CHAPTER_NUMBER=1`; tagging loop runs zero iterations |
| Non-standard MP3 naming | Chapter number parsing may fail; falls back to `TRACKS_PROCESSED` |

## Testing Considerations

- Test with single input file
- Test with multiple input files (verify bug)
- Test with missing input file
- Test with MP3 but no CUE
- Test with M4B
- Test with pre-existing MP3 files
- Test chapter number detection with various naming patterns