# Concurrency and Scheduling

## Threading Model

**Single-threaded, sequential execution**. No parallelism, no background jobs, no async operations.

## Execution Flow

```
Main thread
    ├── Global init
    ├── Function definitions
    ├── Metadata resolution (sequential function calls)
    ├── Format-specific processing (one branch)
    │   ├── Chapter list generation
    │   ├── Audio splitting (sequential ffmpeg calls)
    │   └── Cleanup
    ├── Tagging loop (sequential id3v2 calls)
    └── BookSonic file writes
```

## Scheduling

No scheduler. Script runs to completion when invoked.

## Locking

No locks. No shared state between runs.

### Race Conditions

**Concurrent runs in same directory**:
- Both write to `.chapters.txt`, `.tmp.txt` → corruption
- Both write `reader.txt`, `desc.txt` → last write wins
- Both create `Chapter N.mp3` → overwrite or conflict

**Mitigation**: Run one book per directory, or use separate directories.

## Resource Usage

### CPU

- `ffprobe`: One call per MP3 file (duration calculation)
- `ffmpeg`: One call per chapter (audio splitting)
- `id3v2`: One call per chapter (tagging)
- `bc`/`dc`: One call (duration formatting)

### Memory

Minimal. Bash variables only. External tools manage their own memory.

### Disk I/O

- Reads: Input audio file, CUE/M4B, metadata.txt
- Writes: Chapter MP3s (one per chapter), reader.txt, desc.txt
- Temp: .chapters.txt, .tmp.txt

### Network

None.

## Concurrency Control

None implemented. For parallel processing, user must:
1. Run in separate directories
2. Use external orchestration (GNU parallel, xargs, etc.)

## Future Concurrency Considerations

If parallelism added:
1. Chapter splitting could be parallelized (independent ffmpeg calls)
2. Tagging could be parallelized (independent id3v2 calls)
3. Need temporary file namespacing (per-process)
4. Need output coordination (avoid overwrites)
5. Consider ffmpeg thread count (`-threads`)

## Scheduling Integration

No cron, systemd, or scheduler integration. Manual or wrapper-script invocation only.