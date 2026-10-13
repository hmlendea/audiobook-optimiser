# Data Model

## Metadata Fields

| Field | Source | Type | Default | Description |
|-------|--------|------|---------|-------------|
| `TITLE` | `metadata.txt` title OR filename (stem) | string | derived from input | Primary book title |
| `SUBTITLE` | `metadata.txt` subtitle | string | empty | Book subtitle |
| `AUTHOR` | `metadata.txt` author | string | empty | Book author |
| `YEAR` | `metadata.txt` year | string (4-digit) | empty | Publication year |
| `SERIES_NAME` | `metadata.txt` series | string | empty | Series name |
| `SERIES_ORDER` | `metadata.txt` series_order | string (integer) | empty | Book order in series |
| `NARRATOR_NAME` | `metadata.txt` narrator OR `reader.txt` first line | string | empty | Narrator name |
| `DURATION` | `getDuration()` output | string (HH:MM:SS) | computed | Total audio duration |
| `DESCRIPTION` | `getDescription()` output | string | generated | Human-readable description |

## Chapter Structure

| Field | Source | Type | Description |
|-------|--------|------|-------------|
| `CHAPTER_NUMBER` | Parsed from filename OR sequential | integer | Chapter number (1-based) |
| `CHAPTER_TITLE` | Parsed from filename OR "Chapter N" | string | Chapter title/display name |
| `CHAPTER_DESCRIPTION` | `${CHAPTER_NUMBER} - ${CHAPTER_TITLE}` | string | Combined description |
| `TRACK_NUMBER` | Same as CHAPTER_NUMBER | integer | ID3 TRCK track number |
| `TRACK_INDEX` | Sequential counter starting at 1 | integer | ID3/TRCK sequential index |

## ID3 Tag Mappings

| ID3 Frame | Script Variable | Value | Target Server |
|-----------|----------------|-------|---------------|
| `TIT2` | `CHAPTER_TITLE` | chapter title | AudioBookshelf, BookSonic |
| `TIT3` | (empty string) | — | — |
| `TALB` | `FULL_TITLE` | full book title | AudioBookshelf, BookSonic |
| `TOAL` | (empty string) | — | — |
| `TPE1` | `AUTHOR` | author | AudioBookshelf, BookSonic |
| `TPE2` | `NARRATOR_NAME` | narrator | AudioBookshelf, BookSonic |
| `TOPE` | `AUTHOR` | author (duplicate) | — |
| `TCOM` | `AUTHOR` | author (duplicate) | — |
| `TRCK` | `${TRACK_NUMBER}/${TRACK_INDEX}` | track number/total | AudioBookshelf, BookSonic |
| `TYER` | `YEAR` | year | AudioBookshelf, BookSonic |
| `TCON` | "Audio Book" | content type | AudioBookshelf, BookSonic |
| `TLAN` | "eng" | language code | AudioBookshelf, BookSonic |
| `COMM` | `CHAPTER_DESCRIPTION` | chapter description | — |
| — | `NARRATOR_NAME` → `reader.txt` | narrator name | BookSonic |
| — | `DESCRIPTION` → `desc.txt` | description text | BookSonic |

## Metadata Precedence Hierarchy

```
metadata.txt (explicit)
  ↓
reader.txt (narrator fallback)
  ↓
filename stem (title fallback)
  ↓
defaults (empty/omitted)
```

## Data Transformations

### Title Resolution
```
filename stem (e.g., "chapter1.mp3")
    ↓
[ -n "${TITLE}" ] ? metadata.txt value : filename stem
    ↓
TITLE variable
    ↓
getTitle() → getMetadata title OR TITLE
    ↓
FULL_TITLE = TITLE + " - " + SUBTITLE (if subtitle exists)
```

### Description Generation
```
SERIES_NAME + SERIES_ORDER + TITLE + SUBTITLE
    ↓
generateDescription() → nested conditional blocks
    ↓
DESCRIPTION variable
    ↓
[INCLUDE_DURATION_IN_DESCRIPTION] ? " (Duration: ${DURATION})" appended
```

### Narrator Resolution
```
[ -n "${NARRATOR_NAME}" ] (from metadata.txt) ? use it
    ↓
[ -f "reader.txt" ] && grep '^\s*$' reader.txt | head -n 1 ? use first non-empty line
    ↓
NARRATOR_NAME variable
```

## Invariants

- **Input format invariant**: Script only processes `.mp3` files when INPUT_FILE_FORMAT is "mp3" OR `.m4b` when INPUT_FILE_FORMAT is "m4b"
- **Chapter numbering invariant**: CHAPTER_NUMBER defaults to TRACKS_PROCESSED (first chapter number) if not parseable from filename
- **Title non-empty invariant**: TITLE is always set (either from metadata.txt or derived from filename)
- **Duration computed invariant**: DURATION is always computed from ffprobe output of all .mp3 files in directory
- **Output files invariant**: Script always produces `reader.txt` (if NARRATOR_NAME set) and `desc.txt` (if DESCRIPTION set) for BookSonic compatibility