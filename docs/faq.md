# Frequently Asked Questions

## General

### What does this script do?

It processes audiobook files (MP3 with CUE sheets or M4B) to extract chapters, split audio into per-chapter MP3 files, and apply comprehensive ID3 tags for compatibility with AudioBookshelf and BookSonic servers.

### What servers are supported?

- **AudioBookshelf**: Full support via standard ID3 tags
- **BookSonic**: Full support via ID3 tags + `reader.txt` + `desc.txt`
- **Plex/Emby/Jellyfin**: Partial support (may need additional tags)

### Do I need metadata.txt?

No, it's optional. The script falls back to filename for title and generates description from available fields. But metadata.txt is recommended for best results.

## Usage

### How do I run it?

```bash
chmod +x audiobook-optimiser.sh
./audiobook-optimiser.sh book.mp3
# or
./audiobook-optimiser.sh book.m4b
```

### Can I process multiple books at once?

No. The script processes one book per run. For batch processing, wrap in a loop:

```bash
for f in *.mp3; do ./audiobook-optimiser.sh "$f"; done
```

### What if my MP3 doesn't have a CUE file?

The script will skip chapter extraction and just apply ID3 tags to the existing MP3 file(s) in the directory.

### Can I use it on a directory of MP3s without a source file?

Yes, if you have pre-split chapter MP3s, run the script with any MP3 as input (or create a dummy). It will tag all MP3s in the directory.

## Troubleshooting

### "command not found: ffmpeg"

Install ffmpeg: `sudo apt install ffmpeg` (Debian/Ubuntu) or `brew install ffmpeg` (macOS).

### "command not found: id3v2"

Install id3v2: `sudo apt install id3v2` (Debian/Ubuntu) or `brew install id3v2` (macOS).

### Chapters not extracted from CUE

- Verify CUE file has TRACK/TITLE/INDEX lines
- Verify CUE filename matches MP3 stem exactly
- Check CUE encoding (should be UTF-8)

### Chapters not extracted from M4B

- Verify M4B has embedded chapters: `ffmpeg -i book.m4b 2>&1 | grep Chapter`
- Some M4B files use different chapter formats

### Duration shows 00:00:00 for M4B

Known bug: duration calculated before M4B splitting. Workaround: run script twice, or calculate manually.

### Tags not showing in AudioBookshelf

- Verify ID3 tags written: `id3v2 -l Chapter\ 1.mp3`
- Check server logs for parsing errors
- Ensure server scans for changes

### Filenames with spaces cause issues

Known limitation. Quote variables in script (already mostly done). Avoid spaces in filenames if possible.

## Configuration

### How do I set the narrator?

Add to `metadata.txt`:
```
narrator=John Narrator
```
Or create `reader.txt` with narrator name on first line.

### How do I set series information?

Add to `metadata.txt`:
```
series=Series Name
series_order=3
```

### Can I include duration in description?

Edit line 1 of script:
```bash
INCLUDE_DURATION_IN_DESCRIPTION=true
```

### What metadata fields are supported?

See [Configuration](./configuration.md) for complete list.

## Development

### Can I contribute?

Yes, submit PRs. See [Change Guide](./change-guide.md) for modification patterns.

### How do I test changes?

Manual testing with various input formats. No automated test suite exists yet.

### What Bash version is required?

Bash 4.0+ (uses `[[ ]]`, arrays, parameter expansion).

## Known Issues

See [Ambiguities and Open Questions](./ambiguities-and-open-questions.md) for complete list.