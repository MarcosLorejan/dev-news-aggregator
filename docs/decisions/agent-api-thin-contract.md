---
type: Decision
title: Agent API v1 is a thinner contract than articles JSON
description: Why /api/v1 stays a stable, smaller surface than the rich HTML/JSON feed.
tags: [api, agents, decision]
resource: app/controllers/api/v1/
---

# Agent API v1 is a thinner contract than articles JSON

## Context

The HTML/JSON articles index accumulated many filters (interests, content type, duration, tags, scores). Machine clients need a **stable**, predictable contract. Mirroring every UI param onto `/api/v1` would couple agents to a moving feed surface and complicate auth/rate-limit semantics.

## Decision

- Ship a dedicated `/api/v1` under `ActionController::API` (no CSRF / `allow_browser`).
- Keep v1 list/search params intentionally small (`q`, `sort`, `show_read`, pagination).
- Leave richer feed filters on `/articles.json` / `.atom` until explicitly versioned onto the agent API.
- Mutations (bookmark/dismiss) use optional HTTP Basic + Rack::Attack limits.

## Consequences

- Agents should prefer `/api/v1` over scraping HTML, but must not assume parity with the SPA feed.
- Expanding v1 is a conscious API change — document in [AGENT_API.md](../AGENT_API.md); do not silently copy every `ArticlesController` param.
- UI and agent clients can evolve on different clocks.

## See also

- How-to: [AGENT_API.md](../AGENT_API.md), [KEYWORD_FILTERS.md](../KEYWORD_FILTERS.md)
