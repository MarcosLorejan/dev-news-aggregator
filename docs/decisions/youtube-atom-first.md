---
type: Decision
title: YouTube channel Atom before Data API
description: Why channel uploads use public Atom feeds first and treat Data API search as a scarce budget.
tags: [ingestion, youtube, decision]
resource: app/services/news_fetchers/youtube_fetcher.rb
---

# YouTube channel Atom before Data API

## Context

YouTube Data API quota is easy to burn (`search.list` especially). The product goal is “short relevant videos in the same feed,” which mostly means **known channels’ uploads**, not open-ended search on every fetch.

## Decision

- Default path: public channel Atom (`feeds/videos.xml?channel_id=…`) — no API key, no quota.
- Optional `YOUTUBE_API_KEY`: batch `videos.list` enrichment (duration/stats) and opt-in, budgeted `search.list` discovery.
- Never run keyword discovery on the same cadence as hourly Atom/RSS fetches.

## Consequences

- Without a key, videos appear without duration until enrichment is configured.
- Agents debugging “missing duration” or “no discovery” should check key + config flags, not assume Atom is broken.
- Adding channels at `/sources` is the scalable path; search is a scarce supplement.

## See also

- How-to: [YOUTUBE.md](../YOUTUBE.md)
