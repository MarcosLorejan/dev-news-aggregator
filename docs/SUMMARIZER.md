# Optional article summarizer

Pluggable short summaries for article show pages. Disabled by default so the core app never depends on an LLM.

## Providers

Set `ARTICLE_SUMMARIZER_PROVIDER`:

| Value | Behavior |
|-------|----------|
| `none` (default) | Summarizer off. Show pages still load; `POST /articles/:id/summarize` returns `error: summarizer_disabled`. |
| `heuristic` | Offline extractive summary from title/description. No network; safe for CI and local demos. |
| `openai` | Cloud chat completions (`OPENAI_API_KEY` required). |
| `ollama` | Local Ollama HTTP API (`OLLAMA_BASE_URL`, default `http://127.0.0.1:11434`). |

Unknown provider names fall back to `none`.

## Environment

See `.env.example`. Do not commit real API keys.

| Variable | Used by | Notes |
|----------|---------|-------|
| `ARTICLE_SUMMARIZER_PROVIDER` | all | `none`, `heuristic`, `openai`, or `ollama` |
| `OPENAI_API_KEY` | openai | Required when provider is `openai` |
| `OPENAI_API_URL` | openai | Optional; defaults to OpenAI chat completions |
| `OPENAI_MODEL` | openai | Optional; default `gpt-4o-mini` |
| `OLLAMA_BASE_URL` | ollama | Optional; default `http://127.0.0.1:11434` |
| `OLLAMA_MODEL` | ollama | Optional; default `llama3.2` |

## Caching and failure behavior

- Successful summaries are stored on `articles.summary` / `summary_provider` / `summarized_at`.
- Re-requesting summarize returns the cached value unless `force=true`.
- Provider errors are logged and returned as JSON `error`; they do **not** raise on article show.
- Article show only returns cached summary fields — it never calls a remote provider.

## API

- `GET /articles/:id.json` includes `summary`, `summary_provider`, `summarized_at`, and `summarizer: { enabled, provider }`.
- `POST /articles/:id/summarize` generates (or returns cached) summary. Optional `force=true`. Honors mutating HTTP Basic when configured.
