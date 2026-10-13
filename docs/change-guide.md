# Change Guide

## Common Modification Areas

### Adding a New Metadata Field

1. **Add to metadata.txt parsing**: No code change needed (uses generic `getMetadata`)
2. **Add global variable**: Line ~152-180, add `NEW_FIELD="$(getMetadata new_field)"`
3. **Use in description**: Modify `generateDescription()` (lines 87-130)
4. **Add to ID3 tags**: Modify tagging loop (lines 212-340), add appropriate id3v2 flag
5. **Update documentation**: [data-model.md](./data-model.md), [configuration.md](./configuration.md)

### Adding a New ID3 Tag

1. **Find appropriate id3v2 flag**: `id3v2 --help` lists available frames
2. **Add to tagging loop**: Insert new `--FRAME "value"` line
3. **Consider duplicates**: Some frames set multiple times (see [id3-tagging.md](../components/id3-tagging.md))
4. **Test with target servers**: AudioBookshelf, BookSonic

### Supporting a New Input Format

1. **Add format detection**: Extend `INPUT_FILE_FORMAT` logic (line 15)
2. **Add processing branch**: New `elif` block after line 210
3. **Implement chapter extraction**: New `generate_chapters_list_from_XXX()` function
4. **Reuse `extract_chapters_from_file()`**: Works with any timestamp format
5. **Update documentation**: [file-discovery.md](../components/file-discovery.md), [flows/](../flows/)

### Modifying Chapter Naming

1. **Change output filename**: Modify `CHAPTER_FILE` in `extract_chapters_from_file()` (line ~205)
2. **Update parsing logic**: Modify chapter number/title extraction in tagging loop (lines 215-230)
3. **Update BookSonic files**: No change needed (independent of chapter naming)

### Changing Duration Calculation

1. **Modify `getDuration()`**: Lines 17-35
2. **Consider M4B bug**: Duration called before splitting for M4B
3. **Options**:
   - Calculate from source file (ffprobe on input)
   - Calculate after splitting (sum chapter MP3s)
   - Move `DURATION` computation after chapter extraction

## Safe Modification Patterns

### 1. Always Test Dependencies First

```bash
# Add at top of script
check_deps() {
    for cmd in ffmpeg ffprobe id3v2 bc dc; do
        command -v "$cmd" >/dev/null || { echo "Missing: $cmd"; exit 1; }
    done
}
check_deps
```

### 2. Validate Inputs

```bash
# Add after global initialization
[ -f "$INPUT_FILE" ] || { echo "Input file not found: $INPUT_FILE"; exit 1; }
```

### 3. Check Exit Codes

```bash
# Wrap external calls
run_ffmpeg() {
    ffmpeg "$@" || { echo "ffmpeg failed: $*" >&2; return 1; }
}
```

### 4. Use Local Variables in Functions

```bash
# Good: local variables
function my_func() {
    local var="value"
    ...
}

# Bad: global pollution
function my_func() {
    var="value"
    ...
}
```

### 5. Quote Variables

```bash
# Good
ffmpeg -i "$INPUT_FILE" ...

# Bad (breaks on spaces)
ffmpeg -i $INPUT_FILE ...
```

## Testing Changes

### Manual Testing Checklist

- [ ] MP3 + CUE with metadata.txt
- [ ] MP3 + CUE without metadata.txt
- [ ] MP3 without CUE
- [ ] M4B with metadata.txt
- [ ] M4B without metadata.txt
- [ ] Missing input file
- [ ] Missing dependencies
- [ ] Filenames with spaces
- [ ] Special characters in metadata

### Automated Testing (Not Currently Implemented)

Recommended test structure:
```
tests/
├── test_metadata_extraction.sh
├── test_chapter_processing.sh
├── test_id3_tagging.sh
├── test_mp3_cue_flow.sh
├── test_m4b_flow.sh
└── fixtures/
    ├── sample.mp3
    ├── sample.cue
    ├── sample.m4b
    └── metadata.txt
```

## Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| Filename parsing | Breaks on spaces, special chars | Quote all variables, test edge cases |
| CUE parsing | Complex sed, fragile | Add validation, consider dedicated parser |
| M4B chapter extraction | ffmpeg output format changes | Test with multiple ffmpeg versions |
| ID3 tagging | id3v2 flag changes | Pin id3v2 version, test tags |
| Duration calculation | bc/dc math edge cases | Test long durations (>24h) |
| Global variables | Cross-function coupling | Minimize globals, use function returns |

## Code Style

- Use `[[ ]]` for conditionals
- Use `local` in functions
- Quote all variable expansions
- Use `$(...)` not backticks
- Indent with 4 spaces
- Comment complex sed/awk pipelines