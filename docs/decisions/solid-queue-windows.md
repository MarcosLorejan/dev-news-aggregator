---
type: Decision
title: Solid Queue and dismissal jobs on Windows
description: Why SOLID_QUEUE_IN_PUMA is unused on Windows and what that means for delayed jobs.
tags: [jobs, windows, solid-queue, decision]
resource: config/queue.yml
---

# Solid Queue and dismissal jobs on Windows

## Context

Active Job uses Solid Queue. In Unix development, `SOLID_QUEUE_IN_PUMA=1` runs the supervisor inside Puma via `fork()`. Windows does not provide `fork()`, so that plugin path is not available on typical local Windows setups.

## Decision

- Document and script Unix-friendly `SOLID_QUEUE_IN_PUMA=1 bin/rails server` (or `bin/jobs`) for background work.
- On Windows, `.\dev.ps1` / full-stack helpers start web + Vite **without** assuming in-Puma Solid Queue.
- Production (Kamal/Linux) keeps a real queue DB and Solid Queue enabled.

## Consequences

- Local Windows: dismiss-and-cleanup style jobs may not run until workers run on Unix (WSL, CI, or deploy).
- Do not “fix” Windows by forcing the Puma plugin — use a separate job process on a fork-capable environment instead.
- Agents debugging stuck dismissals should check OS + whether a queue worker is actually running.

## See also

- How-to: [DEVELOPMENT.md](../DEVELOPMENT.md)
