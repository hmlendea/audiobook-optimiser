# Design Decisions

## 1. Single-File Bash Script

**Decision**: Implement entire functionality in one Bash script (~340 lines).

**Rationale**:
- Zero dependencies beyond standard Unix tools
- Easy to copy, deploy, and run
- No build system, package manager, or runtime required
- Transparent and auditable

**Trade-offs**:
- No modularity or code reuse
- Difficult to test individual components
- Global variable pollution
- Harder to maintain as complexity grows

## 2. External Tool Dependencies

**Decision**: Rely on `ffmpeg`, `ffprobe`, `id3v2`, `bc`, `dc`, `awk`, `sed`, `grep` for core functionality.

**Rationale**:
- These tools are mature, well-tested, and handle complex formats (audio, ID3, CUE)
- Reimplementing in Bash would be error-prone and slow
- Standard on most Linux distributions

**Trade-offs**:
- Platform dependency (GNU tools required)
- Version compatibility issues
- No static linking - runtime dependency resolution
- Harder to containerize minimally

## 3. File-Based Configuration (metadata.txt)

**Decision**: Use simple `key=value` text file for configuration.

**Rationale**:
- Human-readable and editable
- No parsing library needed
- Version controllable
- Simple fallback chain (file → defaults)

**Trade-offs**:
- No type validation
- No nested structures
- No schema enforcement
- Line-ending sensitivity

## 4. Linear Pipeline Architecture

**Decision**: Execute stages sequentially with minimal branching.

**Rationale**:
- Simple to understand and debug
- Predictable execution order
- Easy to add logging at each stage

**Trade-offs**:
- No parallelism (sequential chapter processing)
- No early exit on failure
- All stages run even if earlier ones fail

## 5. ID3v2 Tag Duplication

**Decision**: Set multiple ID3 frames with same data (e.g., TPE1 set 4 ways).

**Rationale**:
- Different servers read different frames
- AudioBookshelf uses TPE1/TPE2
- BookSonic may use TCOM/TOPE
- Defensive compatibility

**Trade-offs**:
- Larger tag size
- Potential inconsistency if values diverge
- Redundant work

## 6. BookSonic Compatibility Files

**Decision**: Generate `reader.txt` and `desc.txt` alongside ID3 tags.

**Rationale**:
- BookSonic (legacy) reads these files directly
- Simpler than ensuring all ID3 frames are read
- Zero cost to generate

**Trade-offs**:
- Additional filesystem writes
- Duplication of data in tags
- Legacy support for declining platform

## 7. Duration Calculation Timing

**Decision**: Calculate duration at metadata resolution time (before chapter extraction).

**Rationale**:
- Simple placement in linear flow
- Works for MP3+CUE (MP3s exist)

**Trade-offs**:
- **Bug**: Fails for M4B (no MP3s exist yet)
- Duration not available for M4B description

## 8. Chapter Number Detection from Filenames

**Decision**: Parse chapter numbers from existing MP3 filenames to determine `FIRST_CHAPTER_NUMBER`.

**Rationale**:
- Handles pre-split chapter files
- Allows resuming or processing existing splits

**Trade-offs**:
- Fragile regex parsing
- Processes ALL MP3s in directory (not just created ones)
- Confusing when mixed files present

## 9. No Error Handling

**Decision**: Minimal error checking, rely on tool exit codes.

**Rationale**:
- Simpler code
- Unix philosophy: tools handle their own errors
- Script is for personal/trusted use

**Trade-offs**:
- Silent failures
- No recovery
- Hard to debug in automation

## 10. No Testing Infrastructure

**Decision**: No automated tests.

**Rationale**:
- Personal project, manual verification sufficient
- Bash testing frameworks add complexity
- External tool dependencies hard to mock

**Trade-offs**:
- Regressions likely
- Refactoring risky
- No CI/CD possible

## 11. GNU Tool Assumptions

**Decision**: Use GNU-specific flags (`sed -i`, `sort -h`, `grep -P` patterns).

**Rationale**:
- Primary target is Linux
- GNU tools are standard on Linux
- More powerful features

**Trade-offs**:
- Breaks on macOS/BSD without GNU coreutils
- Portability issues
- Requires documentation

## 12. Fixed Temporary Filenames

**Decision**: Use `.chapters.txt` and `.tmp.txt` in current directory.

**Rationale**:
- Simple, predictable names
- Easy to inspect during debugging

**Trade-offs**:
- Race conditions with concurrent runs
- Pollution if script crashes
- Not suitable for parallel processing