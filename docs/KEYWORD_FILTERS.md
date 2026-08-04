---
type: Guide
title: Keyword interests and filtering
description: Interest presets, keyword query params, and how they combine with category and tag filters.
tags: [filtering, interests, api]
resource: app/models/keyword_filter.rb
---

# Keyword interests & filtering

Drive the feed from personal topics (ruby, rails, rust, software architecture, AI performance) in addition to source categories and free-text search.

*Why presets + query params:* [decisions/keyword-interests.md](decisions/keyword-interests.md).

## Concepts

| Mechanism | What it is | Where it lives |
|-----------|------------|----------------|
| **Interests** (`KeywordFilter`) | Saved presets: a name + list of terms | `keyword_filters` table; UI at `/interests` |
| **Source categories** | UI groupings of `source_type` (HN, Dev.to, Reddit, …) | `ArticlesHelper::CATEGORIES` |
| **Topic tags** | Per-article tags from heuristics | `tags` / `article_tags` (`?tag=` filter) |
| **Free-text search** | Single `q` string (trigram + ILIKE) | `Article.search` |

Interests filter by matching terms against **title + description**. They are orthogonal to category and tag filters: all active filters AND together.

## API (articles index)

`GET /articles.json` and `GET /articles.atom` share the same filter scope.

| Param | Description |
|-------|-------------|
| `keywords` | Comma-separated terms (or repeated values). Multi-word tokens stay phrases (`software architecture`). |
| `match` | `any` (default, OR) or `all` (AND every term). |
| `interest` | Single interest slug (e.g. `ruby`). Expands to that preset’s terms. |
| `interests` | Comma-separated slugs. Union of those presets’ terms. Unknown slug → empty result. |
| `q` | Free-text search (trigram similarity when available). |
| `category` | Source-category slug. |
| `tag` | Topic tag slug. |
| `min_score` / `top_percent` / `sort` / `show_read` / `page` | Unchanged score/sort/pagination params. |
| `content_type` | `video` or `article` (absent = both). See [YOUTUBE.md](YOUTUBE.md). |
| `max_duration` | Max video length in **minutes**; text articles untouched; unknown duration included. |

### Combining filters

1. Explicit `keywords` and expanded `interest` / `interests` terms are **unioned**, then `match` applies to that combined list.
2. The keyword filter is then AND-ed with `q`, `category`, `tag`, and score filters.

Examples:

```bash
# Any of these terms
curl "http://localhost:3000/articles.json?keywords=ruby,rust"

# Every term must match
curl "http://localhost:3000/articles.json?keywords=rails,performance&match=all"

# Saved interest preset
curl "http://localhost:3000/articles.json?interest=software-architecture"

# Several interests + an extra ad-hoc term
curl "http://localhost:3000/articles.json?interests=ruby,rust&keywords=wasm"

# Atom consumers get the same filters
curl "http://localhost:3000/articles.atom?interests=ai-performance&min_score=50"
```

### Matched keywords in the JSON payload

When a keyword/interest filter is active, each article includes `matched_keywords`: the subset of the requested terms that appear in that article’s title or description. The field is omitted when no keyword filter is applied. The feed UI shows up to three badges plus a `+N` overflow.

## Matching semantics

- Case-insensitive substring match on `title` and `description` (`ILIKE`).
- Terms are trimmed; blank tokens dropped; duplicates collapsed (case-insensitive).
- Multi-word terms stay whole phrases (no split on spaces).
- Cap: `Article::MAX_KEYWORDS` (20) after normalization.
- LIKE metacharacters (`%`, `_`) in terms are escaped.

## Managing interests

### UI

`/interests` lists presets with match counts, create/edit terms (chip input), toggle `active`, reorder (up/down), and delete (confirm). Writes use the same mutating HTTP Basic auth as Sources when configured.

Feed chips: `InterestFilter` on the articles index reads `?interests=` and multi-selects slugs.

### API

```
GET    /keyword_filters.json
POST   /keyword_filters.json      { "keyword_filter": { "name", "terms" } }
PATCH  /keyword_filters/:id.json  { "keyword_filter": { "name", "terms", "active", "position" } }
DELETE /keyword_filters/:id.json
```

`terms` may be an array or a comma-separated string. Index responses include `article_count` (kept, non-dismissed articles inside the retention window) computed in one query via `Article.keyword_match_counts`.

### Defaults & seeding

Starter presets live under `interests:` in `config/news_aggregator.yml`. `KeywordFilter.bootstrap_defaults!` (also called from `db/seeds.rb` and on an empty `GET /keyword_filters`) creates missing slugs only — local edits are not overwritten.

## Performance

Trigram indexes on `articles.title` and `articles.description` (`pg_trgm`) keep leading-wildcard `ILIKE` usable. Prefer saved interests or a short `keywords` list over very long OR chains. Listing interests uses a single conditional-count query, not N separate `COUNT(*)`s.

## Related code

- Model: `app/models/keyword_filter.rb`, `Article.matching_keywords` / `matched_keywords_for`
- Controllers: `KeywordFiltersController`, `ArticlesController#apply_keyword_filter`
- Frontend: `InterestFilter`, `InterestsIndexPage`, `api/keywordFilters.ts`
