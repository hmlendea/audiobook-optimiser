# Logging

## Logging Framework

The script uses **no formal logging framework**. All output is via `echo` statements to stdout/stderr.

## Log Levels

No structured log levels. Output categories:

| Category | Method | Example |
|----------|--------|---------|
| Progress | `echo` | `echo "Extracting chapter 1 of 15..."` |
| Metadata | `echo` | `echo "Title: The Book"` |
| Errors | Implicit (tool stderr) | `ffmpeg` errors to stderr |

## Structured Fields

None. No structured logging (JSON, key-value pairs, etc.).

## Correlation

No correlation IDs, trace IDs, or request IDs. Each run is independent.

## Sinks/Destinations

| Destination | Content |
|-------------|---------|
| stdout | Progress messages, metadata summary |
| stderr | External tool errors (ffmpeg, id3v2, etc.) |

## Redaction/Masking

No redaction. All metadata printed in plain text:
- Title, author, narrator, series info
- File paths
- Chapter timestamps

## Retention

No log retention. Output only visible during execution.

## Sampling

No sampling. All output printed.

## Performance Considerations

- Minimal overhead (simple `echo`)
- No async logging
- No buffering control

## Error Logging

External tool errors appear on stderr:
- `ffmpeg` encoding errors
- `id3v2` tag write errors
- `ffprobe` probe errors

No stack traces, context, or structured error objects.

## Audit Logging

No audit logging. No security-relevant events tracked.

## Configuration

No logging configuration. Output is hardcoded.

## Recommended Improvements

### 1. Add Structured Logging

```bash
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

log_debug() {
    [ "${DEBUG:-false}" = "true" ] && echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}
```

### 2. Add Verbosity Control

```bash
VERBOSE="${VERBOSE:-false}"
log_verbose() {
    [ "$VERBOSE" = "true" ] && log_info "$@"
}
```

### 3. Add Log File Option

```bash
LOG_FILE="${LOG_FILE:-}"
log_to_file() {
    [ -n "$LOG_FILE" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}
```

### 4. Redact Sensitive Data

If any sensitive data were ever added (API keys, paths with usernames), add redaction:

```bash
redact() {
    sed 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/[REDACTED]/g'
}
```