# Metadata Extraction Component

## Purpose

Extracts and resolves all book-level metadata from configuration files and fallbacks, producing the global variables used throughout the script.

## Location

`audiobook-optimiser.sh` lines 17-150 (function definitions) and lines 152-180 (invocation)

## Functions

### `getMetadata(key)`

**Signature**: `getMetadata(key: string) → string`

**Implementation**:
```bash
function getMetadata() {
    local KEY="${1}"
    [ -f "${METADATA_FILE}" ] && \
        grep "^${KEY}=" "${METADATA_FILE}" | \
        tail -n 1 | \
        awk -F"=" '{print $2}'
}
```

**Behaviour**:
- Reads `./metadata.txt` (configurable via `METADATA_FILE`)
- Returns the value of the last occurrence of `KEY=value`
- Returns empty string if file missing or key not found
- No validation of value format

**Side effects**: None

### `getTitle()`

**Signature**: `getTitle() → string`

**Implementation**:
```bash
function getTitle() {
    local TITLE=""
    TITLE="$(getMetadata title)"
    if [ -z "${TITLE}" ] && [ -n "${INPUT_FILE_NAME}" ]; then
        TITLE="${INPUT_FILE_NAME%%.*}"
    fi
    echo "${TITLE}"
}
```

**Behaviour**:
1. Tries `metadata.txt` `title` key
2. Falls back to input filename stem (without extension)
3. Always returns non-empty string (filename always exists)

### `getSubtitle()`

**Signature**: `getSubtitle() → string`

**Implementation**:
```bash
function getSubtitle() {
    local SUBTITLE=""
    SUBTITLE="$(getMetadata subtitle)"
    echo "${SUBTITLE}"
}
```

**Behaviour**: Returns `metadata.txt` `subtitle` value or empty string.

### `getFullTitle()`

**Signature**: `getFullTitle() → string`

**Implementation**:
```bash
function getFullTitle() {
    local TITLE="$(getTitle)"
    local SUBTITLE="$(getSubtitle)"
    if [ -n "${SUBTITLE}" ]; then
        echo "${TITLE} - ${SUBTITLE}"
    else
        echo "${TITLE}"
    fi
}
```

**Behaviour**: Combines title and subtitle with ` - ` separator if subtitle exists.

### `getNarrator()`

**Signature**: `getNarrator() → string`

**Implementation**:
```bash
function getNarrator() {
    local NARRATOR_NAME=""
    [ -z "${NARRATOR_NAME}" ] && NARRATOR_NAME="$(getMetadata narrator)"
    [ -z "${NARRATOR_NAME}" ] && [ -f "reader.txt" ] && NARRATOR_NAME="$(grep '^\s*$' reader.txt | head -n 1)"
    echo "${NARRATOR_NAME}"
}
```

**Behaviour**:
1. Tries `metadata.txt` `narrator` key
2. Falls back to `reader.txt` first non-empty line (note: bug in regex - `^\s*$` matches empty lines, not non-empty)
3. Returns empty string if neither source provides value

**Bug**: The regex `^\s*$` matches empty/whitespace-only lines. Should be `^[^\s]` or similar to match non-empty lines.

### `generateDescription()`

**Signature**: `generateDescription() → string`

**Implementation**: Lines 55-95 (complex nested conditionals)

**Behaviour**: Constructs description from available metadata fields in priority order:
1. Series + order + title + subtitle
2. Series + order + title
3. Series + order
4. Series + title
4. Title + subtitle
5. Title only

Prepends author if available, appends narrator if available.

### `getDescription()`

**Signature**: `getDescription() → string`

**Implementation**:
```bash
function getDescription() {
    local DESCRIPTION=""
    [ -z "${DESCRIPTION}" ] && DESCRIPTION="$(getMetadata description)"
    [ -z "${DESCRIPTION}" ] && DESCRIPTION="$(generateDescription)"
    if ${INCLUDE_DURATION_IN_DESCRIPTION} && [ -n "${DURATION}" ]; then
        DESCRIPTION="${DESCRIPTION} (Duration: ${DURATION})"
    fi
    echo "${DESCRIPTION}"
}
```

**Behaviour**:
1. Tries `metadata.txt` `description` key
2. Falls back to `generateDescription()`
3. Optionally appends duration if `INCLUDE_DURATION_IN_DESCRIPTION=true`

## Global Variables Produced

| Variable | Source Function | Description |
|----------|-----------------|-------------|
| `TITLE` | `getTitle()` | Book title |
| `SUBTITLE` | `getSubtitle()` | Book subtitle |
| `FULL_TITLE` | `getFullTitle()` | Combined title + subtitle |
| `AUTHOR` | `getMetadata author` | Book author |
| `YEAR` | `getMetadata year` | Publication year |
| `NARRATOR_NAME` | `getNarrator()` | Narrator name |
| `SERIES_NAME` | `getMetadata series` | Series name |
| `SERIES_ORDER` | `getMetadata series_order` | Series order |
| `DESCRIPTION` | `getDescription()` | Full description |
| `DURATION` | `getDuration()` | Total duration (HH:MM:SS) |

## Data Flow

```
metadata.txt ──→ getMetadata() ──→ individual fields
    │
    ├── title ──→ getTitle() ──→ TITLE
    ├── subtitle ──→ getSubtitle() ──→ SUBTITLE
    ├── author ──→ AUTHOR
    ├── year ──→ YEAR
    ├── narrator ──┐
    ├── series ────┤
    ├── series_order ┤
    └── description ──┘
                        ↓
reader.txt ──→ getNarrator() (fallback) ──→ NARRATOR_NAME
                        ↓
INPUT_FILE_NAME ──→ getTitle() (fallback) ──→ TITLE
                        ↓
getFullTitle() ──→ FULL_TITLE
generateDescription() ──→ DESCRIPTION (fallback)
getDescription() ──→ DESCRIPTION (final)
```

## Invariants

- `TITLE` is never empty (filename fallback guaranteed)
- `FULL_TITLE` equals `TITLE` when `SUBTITLE` is empty
- `DESCRIPTION` is never empty (generated fallback guaranteed)
- `NARRATOR_NAME` may be empty (no hard requirement)

## Error Modes

| Condition | Behaviour |
|-----------|-----------|
| `metadata.txt` missing | All `getMetadata` calls return empty; fallbacks used |
| `metadata.txt` malformed (no `=`) | `awk -F"="` returns whole line; may produce unexpected values |
| `reader.txt` missing | Narrator fallback skipped |
| `reader.txt` regex bug | `grep '^\s*$'` returns empty lines; narrator may be empty incorrectly |

## Testing Considerations

- Test with missing `metadata.txt`
- Test with partial metadata (only title)
- Test with all fields populated
- Test `reader.txt` fallback with various line formats
- Test `INCLUDE_DURATION_IN_DESCRIPTION=true/false`
- Verify `getNarrator()` regex bug