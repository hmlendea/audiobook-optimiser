# Troubleshooting

## Common Issues

### Dependencies Missing

**Symptom**: `command not found: ffmpeg` (or id3v2, bc, dc)

**Solution**: Install missing dependencies:
```bash
# Debian/Ubuntu
sudo apt update && sudo apt install ffmpeg id3v2 bc dc

# macOS
brew install ffmpeg id3v2 bc dc

# Alpine
apk add ffmpeg id3v2 bc dc
```

### No Chapters Extracted from CUE

**Symptom**: Script runs but no `Chapter N.mp3` files created

**Causes**:
1. CUE file missing or wrong name (must match MP3 stem exactly)
2. CUE file malformed (missing TRACK/TITLE/INDEX lines)
3. CUE file encoding issue (try UTF-8)

**Debug**:
```bash
# Check CUE file exists
ls -la *.cue

# Check CUE content
cat book.cue

# Test CUE parsing manually
grep "^\s*\(TRACK\|TITLE\|INDEX\)" book.cue
```

### No Chapters Extracted from M4B

**Symptom**: Script runs but no `Chapter N.mp3` files created

**Causes**:
1. M4B has no embedded chapters
2. ffmpeg output format changed

**Debug**:
```bash
# Check for chapters in M4B
ffmpeg -i book.m4b 2>&1 | grep Chapter

# If no output, M4B has no chapters
```

### Duration Shows 00:00:00 for M4B

**Symptom**: Description shows `(Duration: )` or wrong duration for M4B input

**Cause**: Known bug - duration calculated before M4B splitting

**Workaround**:
- Run script twice (second run will have MP3s to measure)
- Or manually calculate: `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 book.m4b`

### Tags Not Applied

**Symptom**: Chapter MP3s created but missing ID3 tags

**Causes**:
1. id3v2 not installed
2. id3v2 version incompatible
3. File permissions

**Debug**:
```bash
# Check id3v2 installation
id3v2 --version

# Check tags on output file
id3v2 -l "Chapter 1.mp3"

# Check file permissions
ls -la "Chapter 1.mp3"
```

### Filenames with Spaces Cause Issues

**Symptom**: Script fails or produces wrong output with spaces in filenames

**Cause**: Variable quoting issues (mostly fixed but edge cases exist)

**Workaround**: Avoid spaces in filenames, or rename before processing:
```bash
# Rename files to remove spaces
for f in *\ *; do mv "$f" "${f// /_}"; done
```

### Narrator Not Detected from reader.txt

**Symptom**: `reader.txt` exists but narrator not in tags

**Cause**: Known bug in regex (matches empty lines instead of non-empty)

**Fix**: Edit line 83 in script:
```bash
# Change from:
NARRATOR_NAME="$(grep '^\s*$' reader.txt | head -n 1)"
# To:
NARRATOR_NAME="$(grep -v '^\s*$' reader.txt | head -n 1)"
```

### Script Hangs or Runs Forever

**Symptom**: Script doesn't complete

**Causes**:
1. ffmpeg waiting for input (unlikely with -y flag)
2. Large file processing taking long time
3. Infinite loop in chapter processing

**Debug**: Add `set -x` at top of script for trace output.

### Output Files Not Created

**Symptom**: No `Chapter N.mp3`, `reader.txt`, or `desc.txt` created

**Causes**:
1. No write permission in directory
2. Disk full
3. Input file not found

**Debug**:
```bash
# Check permissions
ls -ld .

# Check disk space
df -h .

# Check input file
ls -la "$INPUT_FILE"
```

## Debugging Techniques

### Enable Verbose Output

Add at top of script:
```bash
set -x  # Print each command before execution
```

### Check Intermediate Files

```bash
# Check .chapters.txt content
cat .chapters.txt

# Check .tmp.txt content (if exists)
cat .tmp.txt
```

### Test Individual Functions

```bash
# Source the script to access functions
source audiobook-optimiser.sh

# Test metadata extraction
getMetadata title
getTitle
getNarrator

# Test duration
getDuration
```

### Verify ID3 Tags

```bash
# List all tags on a file
id3v2 -l "Chapter 1.mp3"

# Check specific frame
id3v2 -l "Chapter 1.mp3" | grep TIT2
```

## Platform-Specific Issues

### macOS

- Use `gsed` instead of `sed` for `-i` flag compatibility
- Install GNU coreutils: `brew install coreutils`
- Use `gdate` instead of `date` for some formats

### BSD

- `sort -h` not available, use `sort -n` with zero-padded numbers
- `sed -i` requires argument: `sed -i '' 's/.../.../' file`

### Windows (WSL/Git Bash)

- Path separators may cause issues
- Line endings (CRLF) may break script - use `dos2unix`

## Getting Help

1. Check [FAQ](./faq.md)
2. Check [Ambiguities and Open Questions](./ambiguities-and-open-questions.md)
3. Run with `set -x` and capture output
4. Verify all dependencies installed
5. Test with minimal example (small MP3 + simple CUE)