# audiobook-optimiser Documentation

## Repository Summary

`audiobook-optimiser` is a Bash script that processes audiobook files (MP3 with CUE sheets or M4B format) to extract chapters, set ID3 metadata tags, and optimise them for playback on AudioBookshelf or BookSonic servers. It reads metadata from a `metadata.txt` file, extracts chapter timestamps from CUE or M4B files, splits audio into per-chapter MP3 files, and applies comprehensive ID3 tags including title, author, narrator, series information, and chapter details.

## Root Document Map

- [ARCHITECTURE.md](../ARCHITECTURE.md) — High-level architecture (if present)
- [SECURITY.md](../SECURITY.md) — Security model (if present)
- [ROADMAP.md](../ROADMAP.md) — Project roadmap (if present)
- [PRIVACY.md](../PRIVACY.md) — Privacy policy (if present)
- [LICENSE](../LICENSE) — GNU GPL v3 license

## Documentation Catalogue

### Architecture & Design
- [architecture.md](./architecture.md) — High-level architecture complementing root ARCHITECTURE.md
- [design-decisions.md](./design-decisions.md) — Key architectural/design choices and rationale
- [repository-overview.md](./repository-overview.md) — Repository purpose, scope, entry points
- [repository-structure.md](./repository-structure.md) — Source tree layout, module organisation

### Components
- [components/metadata-extraction.md](./components/metadata-extraction.md) — Metadata parsing from metadata.txt and fallback files
- [components/chapter-processing.md](./components/chapter-processing.md) — Chapter extraction from CUE/M4B and audio splitting
- [components/id3-tagging.md](./components/id3-tagging.md) — ID3 tag application using id3v2
- [components/file-discovery.md](./components/file-discovery.md) — Input file detection and format handling

### Flows
- [flows/mp3-cue-processing.md](./flows/mp3-cue-processing.md) — End-to-end flow for MP3 + CUE input
- [flows/m4b-processing.md](./flows/m4b-processing.md) — End-to-end flow for M4B input

### Reference
- [configuration.md](./configuration.md) — Configuration schema, sources, precedence
- [dependencies.md](./dependencies.md) — External dependencies (ffmpeg, ffprobe, id3v2, bc, dc, awk)
- [data-model.md](./data-model.md) — Domain entities: metadata fields, chapter structure, tag mappings
- [error-handling.md](./error-handling.md) — Error taxonomy, handling patterns, recovery
- [invariants.md](./invariants.md) — System-wide invariants and contracts
- [logging.md](./logging.md) — Logging framework, levels, structured fields, sinks
- [testing.md](./testing.md) — Test strategy, organisation, coverage
- [troubleshooting.md](./troubleshooting.md) — Common issues and solutions
- [security.md](./security.md) — Security model, threats, mitigations
- [concurrency-and-scheduling.md](./concurrency-and-scheduling.md) — Threading, async, schedulers, locks
- [state-and-persistence.md](./state-and-persistence.md) — State management, stores, caches
- [integrations.md](./integrations.md) — External system integrations

### Guides
- [quick-start.md](./quick-start.md) — Getting started guide for newcomers
- [build-and-deployment.md](./build-and-deployment.md) — Build pipeline, deployment, environments
- [change-guide.md](./change-guide.md) — How to modify common areas safely
- [documentation-maintenance.md](./documentation-maintenance.md) — How to keep docs current, ownership
- [faq.md](./faq.md) — Frequently asked questions
- [ambiguities-and-open-questions.md](./ambiguities-and-open-questions.md) — Unresolved items, TODOs, known gaps

## Navigation Aids

- **Start here**: [quick-start.md](./quick-start.md) → [repository-overview.md](./repository-overview.md) → [flows/mp3-cue-processing.md](./flows/mp3-cue-processing.md)
- **Deep dive**: [components/](./components/) directory for per-component details
- **Flows**: [flows/](./flows/) for end-to-end execution traces
- **Debugging**: [troubleshooting.md](./troubleshooting.md) → [error-handling.md](./error-handling.md)

## Maintenance Metadata

- Last reviewed: 2026-10-13
- Owner: Repository maintainers
- Coverage status: Initial documentation generation complete