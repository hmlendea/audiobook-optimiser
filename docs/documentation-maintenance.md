# Documentation Maintenance

## Ownership

- Primary: Repository maintainers
- Contributors: Update docs when modifying code

## Update Triggers

Update documentation when:

1. **New features added** → Update relevant component/flow docs
2. **Bugs fixed** → Update error-handling, invariants, troubleshooting
3. **Dependencies changed** → Update dependencies.md
4. **Configuration changed** → Update configuration.md
5. **Architecture changed** → Update architecture.md, repository-overview.md
6. **New input format** → Add flow doc, update file-discovery.md

## Maintenance Process

### 1. Code Change → Doc Update

For each PR/commit:
- Identify affected documentation files
- Update in same commit
- Verify cross-references still valid

### 2. Periodic Review

Quarterly:
- Check for outdated information
- Verify all links work
- Update "Last reviewed" date in INDEX.md

### 3. Documentation Structure

Keep `docs/` structure consistent:
- New component → `components/name.md`
- New flow → `flows/name.md`
- New reference → root `name.md`
- Update INDEX.md catalogue

## Style Guide

### Formatting

- Headings: Sentence case (`## Repository purpose`)
- Code symbols: Backticks with context (``getMetadata()``)
- File paths: Relative from repo root (`audiobook-optimiser.sh`)
- Cross-references: Relative from `docs/` (`[Architecture](./architecture.md)`)

### Content Standards

- Every component doc: Purpose, Location, Functions, Data Flow, Invariants, Error Handling, Testing
- Every flow doc: Preconditions, Execution Trace, Postconditions, Data Flow, Error Scenarios
- Every reference doc: Complete coverage of topic

## Tools

- Markdown linting: `markdownlint` (if available)
- Link checking: `markdown-link-check` (if available)
- Spell check: `cspell` (if available)

## Versioning

Documentation version matches code (no separate versioning). Git history tracks changes.