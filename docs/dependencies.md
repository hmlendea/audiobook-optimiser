# Dependencies

## External Tools (Required)

| Tool | Purpose | Version Tested | Installation |
|------|---------|----------------|--------------|
| `bash` | Script interpreter | 4.0+ | System package manager |
| `ffmpeg` | Audio splitting, M4B chapter extraction | 4.0+ | `apt install ffmpeg` / `brew install ffmpeg` |
| `ffprobe` | Duration calculation (part of ffmpeg) | 4.0+ | Included with ffmpeg |
| `id3v2` | ID3 tag writing | 0.1.12+ | `apt install id3v2` / `brew install id3v2` |
| `bc` | Floating-point arithmetic for duration | 1.07+ | `apt install bc` / `brew install bc` |
| `dc` | Duration formatting (HH:MM:SS) | 1.4.1+ | `apt install dc` / `brew install dc` |
| `awk` | Text processing, field extraction | GNU awk 4.0+ | System default |
| `sed` | Stream editing for CUE/M4B parsing | GNU sed 4.0+ | System default |
| `grep` | Pattern matching | GNU grep 3.0+ | System default |
| `cat` | File concatenation | GNU coreutils | System default |
| `head`/`tail` | Line selection | GNU coreutils | System default |
| `sort` | Numerical sorting for chapter detection | GNU coreutils | System default |
| `wc` | Line counting | GNU coreutils | System default |
| `ls` | File listing | GNU coreutils | System default |
| `basename` | Path manipulation | GNU coreutils | System default |
| `rm` | File removal | GNU coreutils | System default |
| `mv` | File move/rename | GNU coreutils | System default |

## External Tools (Optional / Fallback)

| Tool | Purpose | Notes |
|------|---------|-------|
| `mp3info` | Alternative ID3 tagging (commented out) | Lines 335-342, not used in current version |

## Internal Dependencies

### File Dependencies

| File | Produced By | Consumed By | Purpose |
|------|-------------|-------------|---------|
| `metadata.txt` | User | `getMetadata()` | Primary configuration |
| `reader.txt` | Script (if NARRATOR_NAME set) | `getNarrator()` fallback | BookSonic narrator file |
| `desc.txt` | Script (if DESCRIPTION set) | — | BookSonic description file |
| `.chapters.txt` | `generate_chapters_list_from_cue/m4b` | `extract_chapters_from_file` | Chapter timestamps |
| `.tmp.txt` | `generate_chapters_list_from_cue/m4b` | Internal temp | Intermediate processing |
| `*.mp3` (input) | User / previous run | `getDuration()`, tagging loop | Source audio files |
| `*.cue` | User | `generate_chapters_list_from_cue` | Chapter timestamps for MP3 |
| `*.m4b` | User | `generate_chapters_list_from_m4b` | Source audio + chapters |

### Function Dependencies

```
getDuration()
    └── ffprobe, bc, dc, awk

getMetadata(key)
    └── grep, awk

getTitle()
    └── getMetadata("title")

getSubtitle()
    └── getMetadata("subtitle")

getFullTitle()
    └── getTitle(), getSubtitle()

getNarrator()
    └── getMetadata("narrator"), reader.txt

generateDescription()
    └── SERIES_NAME, SERIES_ORDER, TITLE, SUBTITLE, AUTHOR, NARRATOR_NAME

getDescription()
    └── getMetadata("description"), generateDescription()

generate_chapters_list_from_cue(cue_file)
    └── grep, sed, awk, wc

generate_chapters_list_from_m4b(m4b_file)
    └── ffmpeg, grep, sed

extract_chapters_from_file(source_file)
    └── .chapters.txt, ffmpeg, awk, wc

Main tagging loop
    └── id3v2, all metadata variables
```

## Version Compatibility

| Dependency | Minimum Version | Tested Versions | Notes |
|------------|-----------------|-----------------|-------|
| bash | 4.0 | 4.4, 5.0, 5.1 | Uses arrays, `[[ ]]`, `=~` |
| ffmpeg | 4.0 | 4.4, 5.0, 6.0 | Chapter extraction, audio splitting |
| id3v2 | 0.1.12 | 0.1.12 | ID3v2.3/v2.4 tag writing |
| bc | 1.07 | 1.07.1 | Floating-point math |
| dc | 1.4.1 | 1.4.1 | Stack-based duration formatting |

## Platform Notes

### Linux (Debian/Ubuntu)
```bash
sudo apt update && sudo apt install ffmpeg id3v2 bc dc
```

### macOS (Homebrew)
```bash
brew install ffmpeg id3v2 bc dc
```

### Alpine Linux
```bash
apk add ffmpeg id3v2 bc dc
```

## Dependency Verification

The script does not verify dependencies at startup. Missing tools will cause runtime failures with cryptic error messages. Recommended pre-flight check:

```bash
for cmd in ffmpeg ffprobe id3v2 bc dc awk sed grep; do
    command -v "$cmd" >/dev/null || echo "MISSING: $cmd"
done
```

## Known Issues

1. **dc availability**: `dc` (desk calculator) is not installed by default on some minimal Linux distributions (e.g., Alpine, some containers). The duration formatting will fail silently.
2. **id3v2 vs id3tool**: Some distributions package `id3tool` instead of `id3v2`. The script requires `id3v2` specifically.
3. **GNU vs BSD tools**: Script uses GNU-specific flags (e.g., `sed -i`, `sort -h`). May not work on BSD/macOS without GNU coreutils.
4. **bc/dc precision**: Duration calculation uses floating-point arithmetic; very long audiobooks (>24h) may have formatting edge cases.