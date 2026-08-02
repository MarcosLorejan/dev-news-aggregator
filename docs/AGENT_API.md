# Agent API (v1)

Stable JSON contract for machine clients and coding agents. Prefer these
routes over scraping the HTML UI.

Base path: `/api/v1`

## Auth and rate limits

| Operation | Auth |
|-----------|------|
| `GET` list / show | Public |
| bookmark / unbookmark / dismiss / undismiss | HTTP Basic when `MUTATING_AUTH_USERNAME` and `MUTATING_AUTH_PASSWORD` are set |

In production, Rack::Attack applies global and mutation rate limits (see
`docs/DEVELOPMENT.md`). Exceeded limits return HTTP 429.

These endpoints inherit `ActionController::API` (no CSRF, no `allow_browser`).

## Endpoints

### List / search articles

`GET /api/v1/articles`

Query params:

| Param | Description |
|-------|-------------|
| `q` | Search title/description (trigram + ILIKE when available) |
| `sort` | `published_at` (default), `score`, `comment_count` |
| `show_read` | `true` to include read articles |
| `page`, `per_page` | Pagination (`per_page` max 100) |

Response:

```json
{
  "articles": [ { "id": 1, "title": "...", "url": "...", "source_type": "hacker_news", "score": 10, "bookmarked": false, "read": false, "dismissed": false, "pending_dismissal": false } ],
  "pagination": { "current_page": 1, "per_page": 50, "total_count": 10, "total_pages": 1 }
}
```

### Show article

`GET /api/v1/articles/:id`

### Mutations

| Method | Path | Body / notes |
|--------|------|----------------|
| `POST` | `/api/v1/articles/:id/bookmark` | → `{ "bookmarked": true }` |
| `DELETE` | `/api/v1/articles/:id/unbookmark` | → `{ "bookmarked": false }` |
| `POST` | `/api/v1/articles/:id/dismiss` | → `{ "status": "dismissed", "timeout": 15 }` |
| `DELETE` | `/api/v1/articles/:id/undismiss` | → `{ "status": "restored" }` |

Example:

```bash
curl -u "$MUTATING_AUTH_USERNAME:$MUTATING_AUTH_PASSWORD" \
  -X POST "http://localhost:3000/api/v1/articles/1/bookmark"
```

## MCP follow-up

A Model Context Protocol server that wraps these endpoints (list, search,
bookmark, dismiss) is intentionally deferred. Once this contract is stable,
MCP tools can call `/api/v1` without scraping.
