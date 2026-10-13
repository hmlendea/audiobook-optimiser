# ID3 Tagging Component

## Purpose

Applies comprehensive ID3v2 tags to each chapter MP3 file for compatibility with AudioBookshelf and BookSonic servers.

## Location

`audiobook-optimiser.sh` lines 212-340 (main tagging loop)

## Tag Application

### id3v2 Command Structure

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

### Tag Mapping Table

| id3v2 Flag | ID3 Frame | Value | Description |
|------------|-----------|-------|-------------|
| `-A` | `TALB` | `FULL_TITLE` | Album/Book title |
| `--TALB` | `TALB` | `FULL_TITLE` | Album/Book title (duplicate) |
| `--TOAL` | `TOAL` | `""` | Original album (empty) |
| `-a` | `TPE1` | `AUTHOR` | Lead performer (author) |
| `--TCOM` | `TCOM` | `AUTHOR` | Composer (author duplicate) |
| `--TPE1` | `TPE1` | `AUTHOR` | Lead performer (author duplicate) |
| `--TPE2` | `TPE2` | `NARRATOR_NAME` | Band/orchestra (narrator) |
| `--TOPE` | `TOPE` | `AUTHOR` | Original artist (author duplicate) |
| `-t` | `TIT2` | `CHAPTER_TITLE` | Title/song name (chapter title) |
| `--TIT2` | `TIT2` | `CHAPTER_TITLE` | Title/song name (duplicate) |
| `--TIT3` | `TIT3` | `""` | Subtitle (empty) |
| `-T` | `TRCK` | `TRACK_NUMBER` | Track number |
| `--TRCK` | `TRCK` | `TRACK_INDEX` | Track number/total (sequential index) |
| `-c` | `COMM` | `CHAPTER_DESCRIPTION` | Comment (chapter description) |
| `--COMM` | `COMM` | `CHAPTER_DESCRIPTION` | Comment (duplicate) |
| `-y` | `TYER` | `YEAR` | Year |
| `--TYER` | `TYER` | `YEAR` | Year (duplicate) |
| `--TORY` | `TORY` | `""` | Original release year (empty) |
| `--TCON` | `TCON` | `"Audio Book"` | Content type |
| `--TLAN` | `TLAN` | `"eng"` | Language |

### Duplicate Tags

Several tags are set multiple times with the same value:
- `TALB` set via `-A` and `--TALB`
- `TPE1` set via `-a`, `--TCOM`, `--TPE1`, `--TOPE`
- `TIT2` set via `-t` and `--TIT2`
- `TRCK` set via `-T` and `--TRCK` (different values!)
- `COMM` set via `-c` and `--COMM`
- `TYER` set via `-y` and `--TYER`

**Note**: `-T` sets track number, `--TRCK` sets track index. These are different values.

## Chapter Numbering Logic

### Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `FIRST_CHAPTER_NUMBER` | Detected from existing MP3 filenames or default 1 | Starting chapter number |
| `TRACKS_PROCESSED` | Initialized to `FIRST_CHAPTER_NUMBER` | Running chapter counter |
| `TRACK_INDEX` | Initialized to 1 | Sequential track index (1, 2, 3...) |
| `CHAPTER_NUMBER` | Parsed from filename or `TRACKS_PROCESSED` | Chapter number for this file |
| `TRACK_NUMBER` | `CHAPTER_NUMBER` (or `CHAPTER_NUMBER+1` if `FIRST_CHAPTER_NUMBER==0`) | ID3 track number |

### Parsing from Filename

```bash
# For files matching "Chapter N.mp3" or "Chapter N - Title.mp3"
CHAPTER_NUMBER=$(echo "${CHAPTER_FILE}" | sed 's/^.*Chapter\s*\([0-9]*\).*/\1/g')
CHAPTER_TITLE=$(echo "${CHAPTER_FILE}" | sed 's/^.*Chapter\s*[0-9][0-9]*\s*\(-\s*\)*\([^\.]*\).mp3/\2/g')

# For files matching "N Title.mp3" (no "Chapter" prefix)
CHAPTER_NUMBER=$(echo "${CHAPTER_FILE}" | sed 's/^[^0-9]*\([0-9]\+\).*\.mp3/\1/g')
CHAPTER_TITLE=$(echo "${CHAPTER_FILE}" | sed 's/^[0-9]*\s*\(.*\)\.mp3$/\1/g')
```

### Normalization

```bash
CHAPTER_NUMBER=$(echo "${CHAPTER_NUMBER}" | sed 's/^0*\([0-9]\)/\1/g')  # Strip leading zeros
TRACK_NUMBER=${CHAPTER_NUMBER}
[[ "${FIRST_CHAPTER_NUMBER}" -eq 0 ]] && TRACK_NUMBER=$((CHAPTER_NUMBER+1))
```

### Description Construction

```bash
CHAPTER_DESCRIPTION="Chapter ${CHAPTER_NUMBER}"
[ "${CHAPTER_DESCRIPTION}" != "${CHAPTER_TITLE}" ] && CHAPTER_DESCRIPTION="${CHAPTER_DESCRIPTION} - ${CHAPTER_TITLE}"
```

## Counter Updates

```bash
TRACKS_PROCESSED=$((TRACKS_PROCESSED+1))
TRACK_INDEX=$((TRACK_INDEX+1))
```

## BookSonic Compatibility Files

```bash
[ -n "${NARRATOR_NAME}" ]    && echo "${NARRATOR_NAME}"  > "reader.txt"
[ -n "${DESCRIPTION}" ]      && echo "${DESCRIPTION}"    > "desc.txt"
```

## Invariants

- Every processed MP3 receives all listed ID3 tags
- `TRACK_INDEX` increments sequentially from 1
- `TRACK_NUMBER` matches chapter number (or chapter+1 if first chapter is 0)
- `reader.txt` and `desc.txt` are overwritten each run (not appended)

## Error Handling

- No error checking on `id3v2` exit code
- Failed tag writes are silent
- No rollback or retry logic

## Testing Considerations

- Verify all ID3 frames are written correctly
- Test with various filename formats
- Test with missing metadata (empty AUTHOR, YEAR, etc.)
- Test `FIRST_CHAPTER_NUMBER` edge cases (0, 1, >1)
- Verify `reader.txt` and `desc.txt` content