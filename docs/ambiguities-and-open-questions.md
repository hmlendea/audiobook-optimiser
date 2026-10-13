# Ambiguities and Open Questions

## Known Bugs

### 1. Duration Calculation for M4B (Critical)

**Location**: Line 152 (`DURATION="$(getDuration)"`)

**Issue**: `getDuration()` sums durations of all `.mp3` files in the directory. For M4B input, no MP3 files exist yet at this point (they are created later by `extract_chapters_from_file`). Therefore `DURATION` is always empty for M4B input.

**Impact**: Duration not included in description even when `INCLUDE_DURATION_IN_DESCRIPTION=true`.

**Fix**: Move `DURATION` computation after chapter extraction, or compute from source M4B file using `ffprobe`.

### 2. Narrator Fallback Regex (Bug)

**Location**: Line 83 (`grep '^\s*$' reader.txt`)

**Issue**: The regex `^\s*$` matches empty/whitespace-only lines, not non-empty lines. The intent is to get the first non-empty line from `reader.txt`.

**Impact**: Narrator may not be detected from `reader.txt` even when it contains valid data.

**Fix**: Change to `grep -v '^\s*$' reader.txt | head -n 1` or `grep '^[^[:space:]]' reader.txt | head -n 1`.

### 3. Multiple Input Arguments (Bug)

**Location**: Line 6 (`INPUT_FILE="${*}"`)

**Issue**: `${*}` concatenates all arguments with spaces. If multiple files are passed, `basename` and parameter expansion produce incorrect results.

**Impact**: Script breaks when called with multiple arguments.

**Fix**: Use `$1` for single file, or add validation for argument count.

### 4. No Error Checking on External Commands

**Location**: Throughout (ffmpeg, id3v2, ffprobe calls)

**Issue**: Exit codes from external tools are never checked. Failures are silent.

**Impact**: Partial or failed processing goes unnoticed.

**Fix**: Add `|| { echo "Error: ..." >&2; exit 1; }` after critical commands.

### 5. No Dependency Verification

**Location**: Script start

**Issue**: No check that `ffmpeg`, `id3v2`, `bc`, `dc` are installed.

**Impact**: Cryptic error messages when tools missing.

**Fix**: Add `check_dependencies()` function at script start.

### 6. GNU Tool Dependencies

**Location**: Throughout (sed -i, sort -h, etc.)

**Issue**: Script uses GNU-specific flags that don't work on BSD/macOS without GNU coreutils.

**Impact**: Script fails on macOS/BSD systems.

**Fix**: Use portable alternatives or document GNU requirement.

## Open Questions

### 1. mp3info Fallback

**Location**: Lines 335-342

**Question**: The `mp3info` command is present but unreachable (preceded by `continue` on line 333). Is this intentional dead code or an incomplete migration from `mp3info` to `id3v2`?

### 2. Chapter Number Detection

**Location**: Lines 170-174

**Question**: The regex `sed 's/^.*\(Chapter\s\)*\([0-9][0-9]*\).*$/\1/g'` is complex. Does it correctly handle all filename patterns? What about files like `01 - Chapter Title.mp3`?

### 3. CUE Parsing Robustness

**Location**: Lines 147-180

**Question**: The CUE parser uses complex sed transformations. How does it handle:
- CUE files with different encodings (UTF-8 vs Latin-1)?
- CUE files with REM lines?
- CUE files with multiple INDEX entries per TRACK?
- CUE files with pregap (INDEX 00)?

### 4. M4B Chapter Extraction

**Location**: Lines 182-200

**Question**: The M4B chapter extraction relies on ffmpeg's stderr output format. How stable is this format across ffmpeg versions? What happens with M4B files that use different chapter metadata formats?

### 5. First Chapter Number Logic

**Location**: Lines 170-174

**Question**: When `FIRST_CHAPTER_NUMBER` is 0, `TRACK_NUMBER` is set to `CHAPTER_NUMBER+1`. What is the rationale? Is this for 0-indexed chapter numbering?

### 6. Empty Metadata Handling

**Question**: When `AUTHOR` is empty, `id3v2 -a ""` is called. Does id3v2 handle empty string arguments correctly? Does it clear the tag or write an empty value?

### 7. Concurrent Execution

**Question**: The script uses fixed filenames (`.chapters.txt`, `.tmp.txt`, `reader.txt`, `desc.txt`). What happens if two instances run simultaneously in the same directory?

## Unimplemented Features

### 1. Batch Processing

No support for processing multiple books in sequence.

### 2. Progress Bar

No progress indication beyond per-chapter messages.

### 3. Resume/Cleanup

No ability to resume interrupted processing or clean up partial results.

### 4. Validation

No validation of:
- Input file existence
- CUE file format
- M4B chapter structure
- metadata.txt format
- Output directory writability

### 5. Testing

No automated test suite exists.

## Future Considerations

### 1. Format Support

- Support for `.aax` (Audible) files
- Support for `.flac` input
- Support for `.ogg` input

### 2. Server Integration

- Direct upload to AudioBookshelf API
- Direct upload to BookSonic API

### 3. Configuration

- Command-line flags for options
- JSON/YAML configuration instead of key=value

### 4. Error Recovery

- Retry failed ffmpeg operations
- Skip failed chapters, continue processing
- Rollback on critical failure