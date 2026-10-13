# Integrations

## External System Integrations

### AudioBookshelf

**Integration Type**: File-based (ID3 tags)

**Mechanism**:
- Script writes standard ID3v2 tags to chapter MP3s
- AudioBookshelf scans directory and reads tags
- No API calls, no authentication

**Required Tags**:
- `TIT2` (chapter title)
- `TALB` (book title)
- `TPE1` (author)
- `TPE2` (narrator)
- `TRCK` (track number)
- `TYER` (year)
- `TCON` (genre: "Audio Book")
- `TLAN` (language: "eng")

**Compatibility**: Full

### BookSonic

**Integration Type**: File-based (ID3 tags + auxiliary files)

**Mechanism**:
- Same ID3 tags as AudioBookshelf
- Additional `reader.txt` (narrator name)
- Additional `desc.txt` (book description)
- BookSonic reads these files directly

**Compatibility**: Full

### Plex Media Server

**Integration Type**: File-based (ID3 tags)

**Mechanism**: Plex reads ID3 tags from audio files

**Notes**: May require additional tags for optimal library matching:
- `TIT1` (content group description)
- `TIT3` (subtitle)
- `TPE3` (conductor)
- `TPE4` (interpreted/remixed by)

**Compatibility**: Partial

### Emby / Jellyfin

**Integration Type**: File-based (ID3 tags)

**Mechanism**: Reads ID3 tags during library scan

**Notes**: Similar to Plex, may benefit from additional tags

**Compatibility**: Partial

## Internal Integrations

### ffmpeg / ffprobe

**Role**: Audio processing backbone

**Operations**:
- `ffprobe`: Duration extraction (`getDuration`)
- `ffmpeg`: Chapter extraction from M4B (`generate_chapters_list_from_m4b`)
- `ffmpeg`: Audio splitting (`extract_chapters_from_file`)

**Version Sensitivity**:
- M4B chapter extraction depends on ffmpeg stderr format
- Audio splitting uses standard `-ss`/`-to` options (stable)

### id3v2

**Role**: ID3 tag writing

**Operations**: All tag writing in tagging loop

**Version Sensitivity**:
- Flag names (`--TALB`, `--TPE1`, etc.) stable
- Frame support varies by version

### bc / dc

**Role**: Duration arithmetic and formatting

**Operations**:
- `bc`: Floating-point sum of durations
- `dc`: Stack-based HH:MM:SS formatting

**Version Sensitivity**: Standard POSIX behavior

### GNU Coreutils (awk, sed, grep, sort, etc.)

**Role**: Text processing, parsing, formatting

**Operations**:
- CUE parsing (complex sed pipeline)
- M4B chapter parsing (grep/sed)
- Filename parsing (sed)
- Duration formatting (awk)

**Version Sensitivity**:
- `sed -i` (GNU extension)
- `sort -h` (GNU extension)
- `grep -P` not used (good)

## Integration Points Summary

| Integration | Type | Direction | Criticality |
|-------------|------|-----------|-------------|
| AudioBookshelf | File tags | Output | High |
| BookSonic | File tags + files | Output | High |
| ffmpeg | CLI | Input/Process | Critical |
| ffprobe | CLI | Input | Critical |
| id3v2 | CLI | Output | Critical |
| bc/dc | CLI | Process | Medium |
| GNU coreutils | CLI | Process | Critical |

## No Network Integrations

The script has no:
- HTTP APIs
- Database connections
- Message queues
- Cloud services
- Authentication systems