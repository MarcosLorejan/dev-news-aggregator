# YouTube ingestion

Short developer videos in the same feed as HN / Dev.to / Reddit. Two paths with very different quota profiles — prefer Atom for channels; treat Data API search as a scarce budget.

## Two ingestion paths

| Path | How | API key? | Quota | What you get |
|------|-----|----------|-------|--------------|
| **Channel Atom** | `GET https://www.youtube.com/feeds/videos.xml?channel_id=UC…` | No | None | Latest ~15 uploads per channel; title, URL, thumbnail, author; **no duration** until enrichment |
| **Data API** | `videos.list`, optional `search.list` / `channels.list` | `YOUTUBE_API_KEY` | Yes | Duration, view/comment counts; keyword discovery |

`FetchNewsJob` order:

1. `NewsAggregatorService.fetch_all_news` (includes `NewsFetchers::YoutubeFetcher` for enabled YouTube `NewsSource`s)
2. `YoutubeKeywordDiscovery.run!` (no-op unless search is enabled + key present)
3. `YoutubeVideoEnricher.enrich!` (no-op without key / when `enrich_with_api` is false)

## Quota (rules of thumb)

YouTube Data API v3 units change over time; verify against [Google’s quota docs](https://developers.google.com/youtube/v3/determine_quota_cost). Practical defaults this app assumes:

| Method | Approx. cost | Notes |
|--------|--------------|-------|
| `videos.list` | **1 unit / call** | Up to **50** video IDs per call — batch aggressively |
| `channels.list` | **1 unit / call** | Used optionally to resolve `@handles` when adding a source |
| `search.list` | Separate expensive bucket (~**100 calls/day** class of limit as of mid-2026) | **Never** call on every hourly fetch |

**Do not** enable keyword search on the same cadence as Atom/RSS. Discovery is opt-in, budgeted, and interval-gated (see config below).

Without `YOUTUBE_API_KEY`:

- Channel Atom ingestion still works
- Cards show thumbnails/authors from Atom; duration stays unknown until a key is added
- Keyword discovery and duration enrichment are skipped
- Handle → `UC…` resolution falls back to scraping the public channel page

## Setup

1. (Optional) Create a Google Cloud API key with YouTube Data API v3 enabled.
2. Copy `.env.example` → `.env` and set:

```bash
# YOUTUBE_API_KEY=
```

3. Manage channels in the UI at `/sources` (YouTube tab) or seed defaults from `config/news_aggregator.yml` → `apis.youtube.channels`.
4. Leave `apis.youtube.search.enabled: false` unless you intentionally want keyword discovery.

Do not commit real keys.

## Config reference (`apis.youtube`)

| Key | Default | Purpose |
|-----|---------|---------|
| `channels` | starter list | Bootstrap `NewsSource` rows (`channel_id`, `name`) |
| `feed_base_url` | YouTube Atom URL | Channel feed endpoint |
| `min_request_interval_seconds` | `2.0` | Throttle between Atom requests |
| `rate_limit_max_retries` | `4` | Backoff on HTTP 429 |
| `enrich_with_api` | `true` | Run `videos.list` when a key is present |
| `enrich_batch_size` | `50` | IDs per `videos.list` call (clamped 1–50) |
| `enrich_max_per_run` | `100` | Max videos enriched per job run |
| `max_duration_seconds` | `1200` | After enrichment, destroy non-bookmarked/non-read videos longer than this (`0` disables) |
| `search.enabled` | `false` | Keyword `search.list` discovery |
| `search.daily_call_budget` | `20` | Hard cap on search calls per UTC day |
| `search.min_interval_hours` | `12` | Per-interest minimum gap between searches |
| `search.max_results` | `10` | Results per search page (one page per interest per run) |
| `search.video_duration` | `medium` | `short` / `medium` / `long` / `any` |
| `search.order` | `date` | `date` / `relevance` / `viewCount` / `rating` |
| `search.relevance_language` | `en` | Passed to `search.list` |
| `search.region_code` | `US` | Passed to `search.list` |
| `search.published_after_days` | `7` | Window when an interest has never been searched |

Daily search call counts are stored in Rails cache (`youtube_search_api_calls:YYYY-MM-DD`). Per-interest last run lives on `FetchRun` rows keyed `youtube_search_<slug>`.

## Sources UI

`/sources` can add YouTube channels by:

- Bare `UC…` channel ID
- `https://www.youtube.com/channel/UC…`
- `@handle` or `https://www.youtube.com/@handle`

`YoutubeChannelValidator` resolves handles (API `channels.list` if keyed, else page scrape), verifies the Atom feed, and stores `channel_id` + `channel_name`. Channels can be toggled and deleted like Reddit sources. Built-in HN / Dev.to sources stay non-deletable.

## Feed filters & article fields

Videos use `content_type: "video"` with optional `duration_seconds`, `thumbnail_url`, and `author`.

`GET /articles.json` / `.atom` (shared scope):

| Param | Description |
|-------|-------------|
| `content_type` | `video` or `article` (absent = both) |
| `max_duration` | Minutes; applied to videos only. Unknown duration stays included. Text articles untouched. |

UI: content-type pills and max-length controls on the articles index; video cards show thumbnail, duration badge, and channel name.

Search hits use `source_type = youtube_search_<interest_slug>`. Channel uploads use `youtube_<channel_id>`. Discovery skips any `external_id` already present from another source so the same video is not double-listed.

## Operational notes

- Datacenter IPs sometimes see **404/5xx** from the public Atom endpoint; treat as transient and rely on `FetchRun` health on `/sources`.
- Atom only exposes **recent** uploads (~15), not the full channel history.
- Invidious / Piped could be future fallbacks for environments that cannot reach YouTube; not implemented.
- Enrichment and search degrade without failing the overall fetch when the key is missing or quota is exceeded.

## Related code

| Piece | Path |
|-------|------|
| Channel Atom fetcher | `app/services/news_fetchers/youtube_fetcher.rb` |
| Duration/stats enricher | `app/services/youtube_video_enricher.rb` |
| Keyword discovery | `app/services/youtube_keyword_discovery.rb` |
| Channel validator | `app/services/youtube_channel_validator.rb` |
| Config accessors | `app/models/news_aggregator_config.rb` |
| YAML | `config/news_aggregator.yml` → `apis.youtube` |
