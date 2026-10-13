# Build and Deployment

## Build Process

No build process required. The script is a standalone Bash script that runs directly.

### Prerequisites

See [Dependencies](./dependencies.md) for required tools.

### Verification

```bash
# Check script syntax
bash -n audiobook-optimiser.sh

# Check dependencies
for cmd in ffmpeg ffprobe id3v2 bc dc awk sed grep; do
    command -v "$cmd" >/dev/null && echo "OK: $cmd" || echo "MISSING: $cmd"
done
```

## Deployment

### Manual Deployment

1. Copy `audiobook-optimiser.sh` to target machine
2. Make executable: `chmod +x audiobook-optimiser.sh`
3. Install dependencies (see [Dependencies](./dependencies.md))
4. Run from directory containing audiobook files

### Container Deployment

```dockerfile
FROM alpine:latest
RUN apk add --no-cache ffmpeg id3v2 bc dc bash coreutils
COPY audiobook-optimiser.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/audiobook-optimiser.sh
WORKDIR /audiobooks
ENTRYPOINT ["audiobook-optimiser.sh"]
```

Build:
```bash
docker build -t audiobook-optimiser .
```

Run:
```bash
docker run -v /path/to/audiobooks:/audiobooks audiobook-optimiser book.mp3
```

## Environments

| Environment | Notes |
|-------------|-------|
| Development | Run directly on host with dependencies installed |
| Production | Same; consider container for isolation |
| CI/CD | Not configured; could add syntax check step |

## Versioning

No versioning scheme. Script has no version number.

## Release Process

No formal release process. Changes committed directly to main branch.

## Rollback

Git revert: `git revert <commit-hash>`