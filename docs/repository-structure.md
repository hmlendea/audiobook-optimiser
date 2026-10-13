# Repository Structure

## Source Tree Layout

```
audiobook-optimiser/
├── audiobook-optimiser.sh    # Main script (single file, ~340 lines)
├── README.md                 # Brief project description
├── LICENSE                   # GNU GPL v3
└── docs/                     # Documentation
```

## Module Organisation

The project is a **single-file Bash script** with no modular decomposition. All logic resides in `audiobook-optimiser.sh`.

### Script Structure

| Lines | Section | Description |
|-------|---------|-------------|
| 1-15 | Global initialization | Constants, input file parsing |
| 17-35 | `getDuration()` | Duration calculation via ffprobe |
| 37-45 | `getMetadata(key)` | Metadata file parsing |
| 47-55 | `getTitle()` | Title resolution with fallback |
| 57-63 | `getSubtitle()` | Subtitle resolution |
| 65-75 | `getFullTitle()` | Combined title + subtitle |
| 77-85 | `getNarrator()` | Narrator resolution with fallback |
| 87-130 | `generateDescription()` | Description construction |
| 132-145 | `getDescription()` | Description resolution |
| 147-150 | `getDuration()` call | Duration computation |
| 152-180 | Metadata resolution | Populate global variables |
| 182-200 | CUE processing | MP3 + CUE chapter extraction |
| 202-210 | M4B processing | M4B chapter extraction |
| 212-340 | Tagging loop | ID3 tag application |

### Function Inventory

| Function | Lines | Purpose |
|----------|-------|---------|
| `getDuration` | 17-35 | Sum MP3 durations via ffprobe |
| `getMetadata` | 37-45 | Read key from metadata.txt |
| `getTitle` | 47-55 | Resolve title with fallback |
| `getSubtitle` | 57-63 | Resolve subtitle |
| `getFullTitle` | 65-75 | Combine title + subtitle |
| `getNarrator` | 77-85 | Resolve narrator with fallback |
| `generateDescription` | 87-130 | Build description from metadata |
| `getDescription` | 132-145 | Resolve description with fallback |
| `generate_chapters_list_from_cue` | 147-180 | Parse CUE to timestamps |
| `generate_chapters_list_from_m4b` | 182-200 | Extract M4B chapters |
| `extract_chapters_from_file` | 202-210 | Split audio into chapters |

### Documentation Structure

```
docs/
├── INDEX.md                          # Master index
├── architecture.md                   # High-level architecture
├── configuration.md                  # Configuration schema
├── data-model.md                     # Domain entities
├── dependencies.md                   # External/internal dependencies
├── error-handling.md                 # Error taxonomy
├── invariants.md                     # System invariants
├── logging.md                        # Logging documentation
├── quick-start.md                    # Getting started
├── repository-overview.md            # Purpose and scope
├── repository-structure.md           # This file
├── ambiguities-and-open-questions.md # Known issues
├── build-and-deployment.md           # Build/deployment
├── change-guide.md                   # Modification guide
├── documentation-maintenance.md      # Doc maintenance
├── faq.md                            # FAQ
├── testing.md                        # Test strategy
├── troubleshooting.md                # Common issues
├── components/
│   ├── metadata-extraction.md        # Metadata component
│   ├── chapter-processing.md         # Chapter processing
│   ├── id3-tagging.md                # ID3 tagging
│   └── file-discovery.md             # File discovery
└── flows/
    ├── mp3-cue-processing.md         # MP3+CUE flow
    └── m4b-processing.md             # M4B flow
```

## File Relationships

```
audiobook-optimiser.sh
    ├── reads → metadata.txt (optional)
    ├── reads → reader.txt (optional, fallback)
    ├── reads → *.cue (optional, MP3 mode)
    ├── reads → *.m4b (input, M4B mode)
    ├── reads → *.mp3 (input, MP3 mode)
    ├── writes → Chapter N.mp3 (output)
    ├── writes → reader.txt (BookSonic compat)
    ├── writes → desc.txt (BookSonic compat)
    ├── writes → .chapters.txt (temp)
    ├── writes → .tmp.txt (temp)
    └── calls → ffmpeg, ffprobe, id3v2, bc, dc, awk, sed, grep
```

## Build Artifacts

None. The script is interpreted at runtime. No compilation step.

## Version Control

- Git repository (`.git/` directory present)
- Single branch (main/master)
- No release tags visible
- No CI/CD configuration