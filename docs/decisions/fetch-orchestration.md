---
type: Decision
title: Fetch orchestration vs per-source fetchers
description: Why NewsAggregatorService orchestrates and each source has its own fetcher object.
tags: [ingestion, architecture, decision]
resource: app/services/news_aggregator_service.rb
---

# Fetch orchestration vs per-source fetchers

## Context

The app ingests many heterogeneous APIs (HN, Dev.to, Reddit Atom/OAuth, YouTube Atom/API). Putting HTTP, parsing, and persistence for every source in one class made failures opaque and new sources expensive.

## Decision

- `NewsAggregatorService` orchestrates: build fetcher list from enabled `NewsSource` rows (else YAML defaults), rescue/log per source, aggregate results.
- Each source implements a focused fetcher under `app/services/news_fetchers/` (and related enrichers/discovery services for YouTube).
- `NewsSource#build_fetcher` (and defaults) is the wiring point for new sources.

## Consequences

- Prefer adding or fixing a fetcher over growing the orchestrator with source-specific branches.
- Per-source `FetchRun` status on the Sources page is intentional — orchestrator success ≠ every source succeeded.
- YouTube keyword discovery/enrichment can run as sibling steps in `FetchNewsJob` without stuffing them into `YoutubeFetcher`.

## See also

- How-to: [DEVELOPMENT.md](../DEVELOPMENT.md) (architecture / adding sources), [YOUTUBE.md](../YOUTUBE.md)
