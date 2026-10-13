# Security

## Threat Model

This is a local file processing script. Threats are limited to:

1. **Input file manipulation**: Malicious audio/CUE files
2. **Configuration injection**: Malicious metadata.txt
3. **Command injection**: Via filenames or metadata values
4. **Path traversal**: Via input file paths
5. **Resource exhaustion**: Large files, many chapters

## Security Controls

### Input Validation

| Vector | Protection |
|--------|------------|
| Input file path | `basename` used, but `${*}` allows injection |
| Metadata values | No validation, passed directly to id3v2 |
| Filenames | Used in ffmpeg/id3v2 commands with quoting |
| CUE file content | Parsed with sed/grep, no eval |

### Command Injection Risks

**High Risk**: `INPUT_FILE="${*}"` (line 6) - all arguments concatenated and used in `basename`, then in ffmpeg commands.

**Medium Risk**: Metadata values passed to `id3v2` - if values contain quotes or backticks, could break command.

**Low Risk**: CUE file parsing - uses `grep`/`sed` on file content, no shell eval.

### Mitigations

1. **Quote all variables**: Most ffmpeg/id3v2 calls use quoted variables
2. **No `eval` or `bash -c`**: Direct command execution
3. **No user input at runtime**: All input via files/arguments

### Recommended Hardening

```bash
# 1. Validate argument count
[ $# -eq 1 ] || { echo "Usage: $0 <input-file>"; exit 1; }
INPUT_FILE="$1"

# 2. Validate input file exists and is readable
[ -f "$INPUT_FILE" ] && [ -r "$INPUT_FILE" ] || { echo "Input file not found or not readable"; exit 1; }

# 3. Sanitize metadata values for id3v2
sanitize() {
    printf '%s' "$1" | sed 's/["`$\\]/\\&/g'
}

# 4. Use arrays for commands
ffmpeg_cmd=(ffmpeg -y -i "$INPUT_FILE" -ss "$START" -to "$END" -map 0:a:0 -c:a:0 mp3 "$OUTPUT")
"${ffmpeg_cmd[@]}"
```

## Data Handling

### Sensitive Data

The script processes:
- Book metadata (title, author, narrator) - not sensitive
- File paths - not sensitive
- No credentials, tokens, or PII

### Data Retention

- Output files: Chapter MP3s, reader.txt, desc.txt (user-controlled)
- Temporary files: .chapters.txt, .tmp.txt (deleted after use)
- No persistent storage

### Data Transmission

No network communication. All processing local.

## Permissions

- Script requires execute permission
- Reads input files in current directory
- Writes output files in current directory
- No elevated privileges needed

## Compliance

- No specific compliance requirements
- GPL v3 license applies to script itself
- Output files inherit user's data handling policies