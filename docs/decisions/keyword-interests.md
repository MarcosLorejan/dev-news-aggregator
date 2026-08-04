---
type: Decision
title: Keyword interests as presets plus query params
description: Why topic filtering uses saved KeywordFilter presets and URL params, not only source categories.
tags: [filtering, interests, decision]
resource: app/models/keyword_filter.rb
---

# Keyword interests as presets plus query params

## Context

Source categories (HN, Dev.to, Reddit, …) group *where* an item came from. Personal reading is driven by *topics* (ruby, rails, rust, architecture) that cut across sources. Encoding topics only as categories or one-off `q=` searches made presets and shareable URLs awkward.

## Decision

- Persist named presets as `KeywordFilter` rows (name + terms).
- Filter the feed with query params (`keywords`, `interest` / `interests`, `match`) that AND with category/tag/score filters.
- Manage presets at `/interests`; keep free-text `q` as orthogonal search.

## Consequences

- Agents and Atom clients must learn interest params separately from categories — see the guide, not only `source_type`.
- Matching is title + description term logic, not embeddings; tune terms, not model weights.
- Do not collapse interests into `ArticlesHelper::CATEGORIES`; they solve different jobs.

## See also

- How-to: [KEYWORD_FILTERS.md](../KEYWORD_FILTERS.md)
