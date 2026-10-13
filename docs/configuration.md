# Configuration

## Configuration Sources

The script uses a single configuration file: `metadata.txt` in the current working directory.

## Configuration Schema

### metadata.txt

A plain-text key=value file. Each line defines a metadata field.

| Key | Required | Default | Description |
|-----|----------|---------|-------------|
| `title` | No | Derived from input filename stem | Primary book title |
| `subtitle` | No | Empty | Book subtitle |
| `author` | No | Empty | Book author |
| `year` | No | Empty | Publication year (4-digit) |
| `narrator` | No | Empty | Narrator name |
| `series` | No | Empty | Series name |
| `series_order` | No | Empty | Book order in series (integer) |
| `description` | No | Generated | Book description |

### Configuration Precedence

1. `metadata.txt` — explicit values (highest priority)
2. `reader.txt` — fallback for narrator (first non-empty line)
3. Input filename stem — fallback for title
4. Generated values — lowest priority (description, duration)

## Runtime Configuration

### INCLUDE_DURATION_IN_DESCRIPTION

- **Type**: boolean
- **Default**: `false`
- **Location**: Line 1 of `audiobook-optimiser.sh`
- **Description**: When `true`, appends ` (Duration: HH:MM:SS)` to the description
- **Effect**: Modifies `getDescription()` output

### METADATA_FILE

- **Type**: string (path)
- **Default**: `./metadata.txt`
- **Location**: Line 3
- **Description**: Path to metadata configuration file

### CHAPTERS_FILE

- **Type**: string (path)
- **Default**: `./.chapters.txt`
- **Location**: Line 4
- **Description**: Temporary file storing chapter timestamps during processing

## Environment Variables

The script does not read any environment variables. All configuration is file-based or hardcoded.

## Input File Handling

| Variable | Source | Description |
|----------|--------|-------------|
| `INPUT_FILE` | Script arguments (`${*}`) | The input audiobook file |
| `INPUT_DIRECTORY` | Hardcoded `.` | Working directory |
| `INPUT_FILE_NAME` | `basename "${INPUT_FILE}"` | Full filename with extension |
| `INPUT_FILE_LABEL` | `${INPUT_FILE_NAME%%.*}` | Filename stem (without extension) |
| `INPUT_FILE_FORMAT` | `${INPUT_FILE_NAME##*.}` | File extension (mp3 or m4b) |

## Conditional Processing

| Condition | Action |
|-----------|--------|
| `INPUT_FILE_FORMAT == "mp3"` AND CUE file exists | Extract chapters from CUE, split MP3 |
| `INPUT_FILE_FORMAT == "mp3"` AND no CUE file | Skip chapter extraction, tag existing MP3s |
| `INPUT_FILE_FORMAT == "m4b"` | Extract chapters from M4B, split to MP3 |
| `*.mp3` files exist in directory | Process all for tagging |
| No `*.mp3` files | `FIRST_CHAPTER_NUMBER` defaults to 1 |

## First Chapter Number Detection

When MP3 files exist in the directory, the script attempts to detect the first chapter number:

```bash
FIRST_CHAPTER_NUMBER=$(ls *.mp3 | \
    sed 's/^.*\(Chapter\s\)*\([0-9][0-9]*\).*$/\1/g' | \
    sort -h | head -n 1 | \
    sed 's/^0*\([0-9]\)/\1/g')
```

- Parses chapter numbers from filenames matching `Chapter N` pattern
- Sorts numerically and takes the minimum
- Strips leading zeros
- Falls back to 1 if no MP3 files or no match