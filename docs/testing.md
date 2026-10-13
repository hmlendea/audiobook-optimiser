# Testing

## Current State

**No automated test suite exists.** All testing is manual.

## Test Strategy (Recommended)

### Unit Tests (Per Function)

| Function | Test Cases |
|----------|------------|
| `getMetadata` | Key exists, key missing, file missing, malformed line |
| `getTitle` | metadata.txt has title, metadata.txt missing title, filename fallback |
| `getSubtitle` | Present, missing |
| `getFullTitle` | With subtitle, without subtitle |
| `getNarrator` | metadata.txt, reader.txt fallback, both missing, regex bug |
| `generateDescription` | All combinations of series/order/title/subtitle/author/narrator |
| `getDescription` | metadata.txt description, generated, with/without duration |
| `getDuration` | Multiple MP3s, single MP3, no MP3s, long duration |
| `generate_chapters_list_from_cue` | Valid CUE, missing TRACK, malformed timestamps |
| `generate_chapters_list_from_m4b` | Valid M4B, no chapters, ffmpeg error |
| `extract_chapters_from_file` | Normal timestamps, END marker, ffmpeg failure |

### Integration Tests (Per Flow)

| Flow | Test Cases |
|------|------------|
| MP3+CUE | Valid CUE, missing CUE, malformed CUE, spaces in filenames |
| M4B | Valid M4B, no chapters, malformed M4B |
| Tagging | All metadata present, partial metadata, empty metadata, special chars |

### End-to-End Tests

| Scenario | Expected Result |
|----------|-----------------|
| MP3+CUE with full metadata | Chapter MP3s with all tags, reader.txt, desc.txt |
| MP3+CUE without metadata | Chapter MP3s with filename-derived tags |
| MP3 without CUE | Original MP3 tagged |
| M4B with full metadata | Chapter MP3s with all tags, reader.txt, desc.txt |
| M4B without metadata | Chapter MP3s with filename-derived tags |

## Test Fixtures Needed

```
tests/fixtures/
├── sample.mp3              # Short MP3 for testing
├── sample.cue              # CUE with 3 chapters
├── sample.m4b              # M4B with 3 chapters
├── metadata_full.txt       # All fields populated
├── metadata_partial.txt    # Only title and author
├── metadata_empty.txt      # Empty file
├── reader.txt              # Narrator name
└── reader_empty.txt        # Empty file
```

## Test Execution

### Manual Test Script Template

```bash
#!/bin/bash
set -e

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Copy fixtures
cp /path/to/fixtures/* .

# Run script
./audiobook-optimiser.sh sample.mp3

# Verify outputs
[ -f "Chapter 1.mp3" ] || exit 1
[ -f "Chapter 2.mp3" ] || exit 1
id3v2 -l "Chapter 1.mp3" | grep -q "TIT2.*Chapter 1" || exit 1

echo "PASS"
```

## Coverage Goals

| Area | Target |
|------|--------|
| Metadata extraction | 100% |
| Chapter processing | 100% |
| ID3 tagging | 100% |
| Error handling | 80% |
| Edge cases | 60% |

## CI/CD Integration

Not currently configured. Recommended:
1. Add syntax check: `bash -n audiobook-optimiser.sh`
2. Add dependency check in CI
3. Run manual test suite in CI (with fixtures)
4. Test on multiple platforms (Linux, macOS)