# Error Handling

## Error Taxonomy

| Category | Examples | Handling |
|----------|----------|----------|
| Missing dependencies | `ffmpeg`, `id3v2`, `bc`, `dc` not installed | Silent failure at point of use |
| Missing input files | Input MP3/M4B/CUE not found | ffmpeg/id3v2 fail with stderr |
| Malformed configuration | `metadata.txt` missing `=`, invalid values | `awk`/`grep` produce unexpected results |
| Malformed CUE/M4B | Missing TRACK lines, no chapters | Empty `.chapters.txt`, zero chapters extracted |
| Tool failures | ffmpeg encoding error, id3v2 write error | Exit code ignored, processing continues |
| Filesystem errors | No write permission, disk full | Tool stderr printed, no recovery |

## Current Handling Patterns

### 1. No Pre-flight Checks

The script does not verify dependencies at startup. Missing tools cause failures deep in execution.

### 2. No Exit Code Checking

```bash
# Example: ffmpeg failure ignored
ffmpeg -y -i "${FILE_TO_EXTRACT}" -ss "${TIMESTAMP_START}" -to "${TIMESTAMP_END}" -map 0:a:0 -c:a:0 mp3 "${CHAPTER_FILE}" 2>/dev/null

# Example: id3v2 failure ignored
id3v2 ... "${CHAPTER_FILE}"
```

### 3. stderr Suppression

Many commands redirect stderr to `/dev/null` or temp files, hiding error messages:
- `ffmpeg ... 2>/dev/null`
- `id3v2 ...` (stderr not captured)
- `ffprobe ...` (stderr not captured)

### 4. No Validation

- No validation of `metadata.txt` format
- No validation of CUE file structure
- No validation of M4B chapter data
- No validation of extracted timestamps
- No validation of chapter MP3 creation success

## Error Propagation

Errors do not propagate. Each stage continues regardless of previous failures:

```
CUE parsing fails
    ↓
.chapters.txt empty/malformed
    ↓
extract_chapters_from_file creates 0 or broken MP3s
    ↓
Tagging loop processes whatever exists
    ↓
reader.txt/desc.txt still written
```

## Recovery Mechanisms

None. The script has no:
- Retry logic
- Rollback/cleanup on failure
- Partial success reporting
- Checkpoint/resume capability

## Recommended Improvements

### 1. Dependency Check at Startup

```bash
check_dependencies() {
    local missing=()
    for cmd in ffmpeg ffprobe id3v2 bc dc awk sed grep; do
        command -v "$cmd" >/dev/null || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing[*]}" >&2
        exit 1
    fi
}
```

### 2. Exit Code Checking

```bash
run_ffmpeg() {
    ffmpeg "$@" || {
        echo "ffmpeg failed: $*" >&2
        return 1
    }
}
```

### 3. Input Validation

```bash
validate_metadata_file() {
    [ -f "$METADATA_FILE" ] || return 0
    while IFS= read -r line; do
        [[ "$line" =~ ^[a-z_]+= ]] || echo "Warning: malformed line in $METADATA_FILE: $line" >&2
    done < "$METADATA_FILE"
}
```

### 4. Structured Error Reporting

```bash
log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

log_warning() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}
```

## Known Error Scenarios

| Scenario | Symptom | Root Cause |
|----------|---------|------------|
| `dc` not installed | Duration shows as empty or wrong | `dc` command fails silently |
| `id3v2` not installed | Tags not applied | `id3v2` command not found |
| CUE file has no TRACK lines | No chapters extracted | `grep` finds nothing |
| M4B has no chapters | No chapters extracted | `ffmpeg` output doesn't match pattern |
| Filename has no chapter number | Chapter numbered sequentially | Regex falls back to counter |
| `reader.txt` has empty lines | Narrator not detected | Bug in `grep '^\s*$'` regex |

## Testing Error Conditions

Test each failure mode:
1. Remove each dependency and run script
2. Provide malformed `metadata.txt`
3. Provide CUE file without TRACK lines
4. Provide M4B without chapters
5. Run without write permissions
6. Run with disk full (simulate)