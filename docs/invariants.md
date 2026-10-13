# Invariants

## System-Wide Invariants

### Input Invariants

1. **Single Input File**: Script expects exactly one input file (MP3 or M4B). Multiple arguments are concatenated and break parsing.
2. **Format Consistency**: `INPUT_FILE_FORMAT` must be "mp3" or "m4b". No validation performed.
3. **CUE Naming**: For MP3 input, CUE file must have identical stem (e.g., `book.mp3` → `book.cue`).
4. **Working Directory**: All file operations occur in current directory (`.`).

### Metadata Invariants

1. **Title Non-Empty**: `TITLE` is always set (metadata.txt or filename stem fallback).
2. **Full Title Construction**: `FULL_TITLE = TITLE` if `SUBTITLE` empty, else `TITLE - SUBTITLE`.
3. **Description Non-Empty**: `DESCRIPTION` always set (metadata.txt or generated fallback).
4. **Duration Computed**: `DURATION` always computed via `getDuration()` (may be empty if no MP3s exist).
5. **Narrator Optional**: `NARRATOR_NAME` may be empty (no hard requirement).

### Chapter Processing Invariants

1. **Sequential Chapters**: Chapter numbers are sequential starting from 1 (or `FIRST_CHAPTER_NUMBER`).
2. **Timestamp Pairs**: `.chapters.txt` contains one timestamp pair per line (start end).
3. **Chapter Files Created**: Each timestamp pair produces one `Chapter N.mp3` file.
4. **All MP3s Tagged**: Tagging loop processes ALL `.mp3` files in directory, not just created ones.

### Tagging Invariants

1. **Complete Tag Set**: Every processed MP3 receives all 19 ID3 frames listed in [id3-tagging.md](../components/id3-tagging.md).
2. **Track Index Sequential**: `TRACK_INDEX` increments 1, 2, 3... for each file processed.
3. **Track Number Matches Chapter**: `TRACK_NUMBER` equals `CHAPTER_NUMBER` (or +1 if `FIRST_CHAPTER_NUMBER==0`).
4. **BookSonic Files**: `reader.txt` and `desc.txt` written if narrator/description available.

### State Invariants

1. **No Persistent State**: Script is stateless between runs (except output files).
2. **Temporary Files Cleaned**: `.chapters.txt` and `.tmp.txt` removed after use.
3. **Idempotent Tagging**: Re-running on same files overwrites tags (no accumulation).

## Contractual Invariants

### AudioBookshelf Compatibility

| Requirement | Implementation |
|-------------|----------------|
| TIT2 (title) | Chapter title |
| TALB (album) | Full book title |
| TPE1 (artist) | Author |
| TPE2 (album artist) | Narrator |
| TRCK (track) | Track number/total |
| TYER (year) | Publication year |
| TCON (genre) | "Audio Book" |
| TLAN (language) | "eng" |

### BookSonic Compatibility

| Requirement | Implementation |
|-------------|----------------|
| All AudioBookshelf tags | ✓ |
| `reader.txt` | Narrator name |
| `desc.txt` | Full description |

## Invariant Violations (Known Bugs)

| Invariant | Violation | Impact |
|-----------|-----------|--------|
| Single input file | Multiple args concatenated | Wrong file processing |
| CUE naming | Not validated | Silent skip of chapter extraction |
| Duration computed | Runs before M4B splitting | Duration=0 for M4B |
| Narrator fallback | Regex bug in `getNarrator()` | May miss narrator from reader.txt |
| All MP3s tagged | Processes pre-existing MP3s | May tag unrelated files |
| Temporary files cleaned | Only `.chapters.txt` removed in main flow | `.tmp.txt` may leak on error |

## Testing Invariants

Each invariant should be verified by tests:
1. Run with valid MP3+CUE → verify all tags present
2. Run with valid M4B → verify all tags present
3. Run with missing metadata.txt → verify fallbacks work
4. Run with missing CUE → verify tagging still works
5. Run with pre-existing MP3s → verify only chapter files tagged (currently violated)
6. Run twice → verify idempotent (tags overwritten)