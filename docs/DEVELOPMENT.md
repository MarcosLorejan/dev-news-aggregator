# Development Guide

Project-specific commands, architecture, and conventions for dev-news-aggregator.

For the directory map, see [REPO_STRUCTURE.md](REPO_STRUCTURE.md). **Update that file whenever you change project structure** (new folders, models, routes, migrations, etc.).

## Development commands

### Prerequisites

- Ruby matching `.ruby-version` (currently 3.3.12) and Bundler
- Node.js 20+ and npm
- Docker Compose (PostgreSQL) or a local Postgres 15 instance

### Setup & database

```bash
# Install dependencies
bundle install

# Start PostgreSQL only (compose has no app service; Rails runs on the host)
docker compose up -d

# Setup primary and queue databases
bin/rails db:prepare
bin/rails db:seed

# Initial news fetch
bin/rails runner "NewsAggregatorService.fetch_all_news"
```

### Running the application

Full-stack development needs **both** Vite (HMR on port 3036) and Rails (port 3000). Prefer this two-process setup (or `.\dev.ps1` on Windows):

```bash
# Terminal 1: Vite
npm run dev

# Terminal 2: Rails (with Solid Queue supervisor in Puma for background jobs)
SOLID_QUEUE_IN_PUMA=1 bin/rails server
```

```powershell
# Windows: starts Postgres (if needed), Vite + Rails, opens the browser
.\dev.ps1

# Or double-click start-app.bat in Explorer (same thing)
```

Note: on Windows, `SOLID_QUEUE_IN_PUMA` is **not** used — Solid Queue’s Puma plugin requires `fork()`, which Windows does not support. The web app still runs; background jobs (e.g. delayed dismissal cleanup) won’t process until you run workers on a Unix-like environment.

Development uses `skipProxy: true` in `config/vite.json` so the browser loads Vite assets directly from port 3036. That avoids blank pages caused by Vite’s many module requests queueing behind a few Puma threads.

`bin/dev` is a thin wrapper that runs **`bin/rails server` only** — it does **not** start Vite. Use it when you only need the Rails process (for example jobs already covered elsewhere); for React HMR, always use `npm run dev` + Rails, or `.\dev.ps1` / `start-app.bat`.

```bash
# Rails-only (no Vite / no HMR)
bin/dev

# Or run job workers in a separate process instead of SOLID_QUEUE_IN_PUMA
bin/jobs
```

Access the app at http://localhost:3000. See [REACT_SETUP.md](REACT_SETUP.md) for frontend details.

### News operations

```bash
# Enqueue background job to fetch news from all sources (non-blocking)
bin/rails news:fetch

# Show last fetch outcome per source
bin/rails news:fetch_status

# Show latest 10 articles
bin/rails news:latest

# Clean old articles (uses retention from config/news_aggregator.yml)
bin/rails news:clean

# Run fetch synchronously (e.g. debugging)
bin/rails runner "NewsAggregatorService.fetch_all_news"
```

### Testing

```bash
# Run all Rails tests
bin/rails test

# Run specific test file
bin/rails test test/models/article_test.rb

# Run specific test
bin/rails test test/controllers/articles_controller_test.rb -n test_index
```

### Frontend testing

React/Vite frontend checks (also see [AGENTS.md](../AGENTS.md#verification) and `bin/validate`):

| Script | Command | Purpose | CI job |
|--------|---------|---------|--------|
| `npm test` | `vitest run` | Frontend unit tests | `frontend_test` |
| `npm run test:watch` | `vitest` | Frontend tests in watch mode | — (local only) |
| `npm run typecheck` | `tsc --noEmit` | TypeScript check | `typecheck` |
| `npm run lint` | `eslint .` | ESLint (TypeScript + React hooks) | `frontend_lint` |
| `npm run lint:fix` | `eslint . --fix` | Auto-fix lint issues | — (local only) |
| `npm run format` | `prettier --write ...` | Format frontend sources | — (not enforced in CI) |
| `npm run format:check` | `prettier --check ...` | Report unformatted files | — (not enforced in CI) |
| `npm run build:test` | `vite build --mode test` | Test-mode Vite build (assets for Rails/system tests) | `test` |
| `npm run build` | `vite build` | Production frontend build | — (deploy / local) |
| `npm run dev` | `vite` | Vite HMR dev server | — (local) |
| `npm run preview` | `vite preview` | Preview production build | — (local) |

```bash
npm test
npm run typecheck
npm run build:test
```

### Code quality

```bash
# Run RuboCop linter
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -a

# Security audit (Ruby)
bin/brakeman

# Lint the frontend (matches CI frontend_lint)
npm run lint

# JS dependency audit (matches CI scan_js)
npm audit --omit=dev --audit-level=moderate
```

Prettier is configured (`.prettierrc.json`) but not enforced: most of the existing frontend predates it, so `npm run format` would rewrite ~30 files. Run it on files you are already touching, or reformat the tree in a dedicated commit — don't mix it into a feature PR.

### Local validation (`bin/validate`)

Prefer the CI-oriented wrapper before opening a PR (documented in [AGENTS.md](../AGENTS.md#verification)):

```bash
bin/validate          # RuboCop, Brakeman, typecheck, npm test, rails test
bin/validate --fast   # skips Brakeman and Rails tests
```

| Check | `bin/validate` | CI job(s) |
|-------|----------------|-----------|
| RuboCop | yes | `lint` |
| Brakeman | yes (skipped with `--fast`) | `scan_ruby` |
| `npm run typecheck` | yes | `typecheck` |
| `npm run lint` | yes | `frontend_lint` |
| `npm test` | yes | `frontend_test` |
| `bin/rails test` | yes (skipped with `--fast`) | `test` (with `COVERAGE=true`) |
| `npm run build:test` | no — run before system tests if needed | `test` |
| `rails test:system` | no | `test` |
| `npm audit` | no | `scan_js` |
| `bundle-audit` | no | `scan_dependencies` |
| `docker build .` | no | `docker_build` |
| Trivy image scan | no | `docker_scan` (CRITICAL/HIGH library vulns; see `.trivyignore`) |

### Cron jobs

```bash
# Update crontab with scheduled jobs
whenever --update-crontab

# View current cron schedule
crontab -l

# Clear crontab
whenever --clear-crontab
```

## Architecture overview

### Core components

**NewsAggregatorService**: Central orchestrator that coordinates all news fetchers. Builds the fetcher list from enabled `NewsSource` records when present, otherwise from `config/news_aggregator.yml` (Hacker News, Dev.to, and configured Reddit subreddits). Handles error logging and aggregates results.

**NewsAggregatorConfig**: Loads `config/news_aggregator.yml` via `Rails.application.config_for`. Provides fetching limits (`max_articles_per_source`), retention settings, Reddit subreddit lists, and API endpoint metadata. Fetchers read article limits from config; `news:clean` uses configured retention days.

**Fetcher architecture**: Modular fetcher system with `NewsFetchers::BaseFetcher` as the abstract base class. Each fetcher (HackerNews, DevTo, Reddit) inherits and implements `fetch_articles`. Common pattern: fetch from API, transform data, call `create_or_update_article`.

**Data models**:
- `Article`: Stores aggregated news with unified schema (title, url, published_at, description, external_id, source_type, score, comment_count)
- `Bookmark`: Tracks bookmarked articles for personal reading list functionality
- `NewsSource`: Database-backed source registry with admin UI at `/sources`. `bootstrap_defaults!` seeds Hacker News, Dev.to, and Reddit subreddits from `config/news_aggregator.yml`. When any enabled records exist, they override the YAML default fetcher list

**Scheduled jobs**: Uses `whenever` gem to run `news:fetch` hourly during business hours (9 AM - 6 PM) and `news:clean` daily at 2 AM. `news:fetch` enqueues `FetchNewsJob` so cron exits immediately; workers process the fetch asynchronously. Logs to `log/cron.log`.

**Background jobs (Solid Queue)**: Active Job uses Solid Queue in development and production. `MakeDismissalPermanentJob` runs 15 seconds after an article is dismissed. In development, start the app with `SOLID_QUEUE_IN_PUMA=1 bin/rails server` (or run `bin/jobs` in a separate terminal). Production uses a dedicated queue database and `SOLID_QUEUE_IN_PUMA=true` in Kamal deploy config.

### Key design patterns

**Service-oriented architecture**: Business logic separated into service classes rather than fat models. Each news source has its own fetcher service.

**Fail-safe aggregation**: If one news source fails, others continue processing. Errors are logged but don't stop the entire aggregation process. Sources run in parallel threads; each fetcher uses configured HTTP timeouts and retries with exponential backoff.

**Idempotent updates**: Articles use `find_or_initialize_by(external_id, source_type)` to prevent duplicates while allowing updates to existing articles.

**Rate limiting awareness**: Per-source article limits come from `NewsAggregatorConfig.max_articles_per_source` (see `config/news_aggregator.yml`). Includes proper error handling for API failures.

### File structure

```
app/
  controllers/articles_controller.rb    # Main web interface
  controllers/sources_controller.rb     # Enable/disable sources, add Reddit subreddits
  models/
    article.rb                          # Article data model
    news_aggregator_config.rb           # YAML config loader for news fetching
    news_source.rb                      # Database-backed source registry
  services/
    news_aggregator_service.rb          # Main orchestrator
    news_fetchers/
      base_fetcher.rb                   # Abstract fetcher base class
      hacker_news_fetcher.rb            # HN API integration
      dev_to_fetcher.rb                 # Dev.to API integration
      reddit_fetcher.rb                 # Reddit API integration
config/news_aggregator.yml              # Fetch limits, retention, subreddit list
lib/tasks/news.rake                     # Rake tasks for news operations
config/schedule.rb                      # Cron job definitions
```

### API integration details

**Hacker News**: Uses Firebase API (`hacker-news.firebaseio.com/v0`). Fetches top stories, then individual story details. Filters out Ask HN posts without URLs.

**Dev.to**: Uses REST API (`dev.to/api/articles`) with query params for pagination and filtering by top posts from last 7 days.

**Reddit**: Multiple instances for different subreddits. Each subreddit is treated as a separate source type in the database. Fetchers read the public Atom feed (`/r/{subreddit}/.rss`) because unauthenticated `.json` listings return HTTP 403. Requests are throttled to reduce rate-limit errors; HTTP failures are recorded on `FetchRun` instead of silent zero-article success.

### Database schema

Articles table uses generic fields to accommodate all news sources:
- `source_type`: String identifier (hacker_news, dev_to, reddit_programming, etc.)
- `external_id`: Source-specific unique identifier
- `score`: Votes/reactions from source (HN score, Dev.to reactions, Reddit upvotes)
- `comment_count`: Source-specific comment counts

### Environment configuration

Copy `.env.example` to `.env` before starting the stack. Docker Compose reads it to create the PostgreSQL container:
- `POSTGRES_USER`: dev_news_user
- `POSTGRES_PASSWORD`: dev_password
- `POSTGRES_DB`: dev_news_aggregator_development

`config/database.yml` falls back to those same credentials (`DB_USERNAME`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`), so Rails connects to the container with no extra setup. Rails does not load `.env` itself — export `DB_*` in your shell only when pointing Rails at a different database. Windows setup (`setup-local-env.ps1`) uses the same credentials.

### Key features

**Article bookmarking**: Users can bookmark articles for later reading. Bookmarks are displayed in a dedicated reading list with category filtering.

**Category filtering**: Articles are grouped into logical categories (Programming Languages, Web Development, Security, AI & Machine Learning, General Tech) for easier browsing.

**Multi-source aggregation**: Default sources are defined in `config/news_aggregator.yml` — Hacker News, Dev.to, and 11 Reddit subreddits (programming, webdev, javascript, ruby, rust, netsec, cybersecurity, technology, MachineLearning, artificial, LocalLLaMA). Override via enabled `NewsSource` records.

### Adding new news sources

**Via config (default path)**:
1. For Reddit: add the subreddit to `config/news_aggregator.yml` under `apis.reddit.subreddits`
2. Adjust `fetching.max_articles_per_source` if needed

**Via database (optional override)**:
1. Create or enable a `NewsSource` record (`NewsSource.bootstrap_defaults!` seeds defaults)
2. Each source's `build_fetcher` method returns the appropriate fetcher instance

**New fetcher type**:
1. Create fetcher in `app/services/news_fetchers/` inheriting from `BaseFetcher`
2. Implement `fetch_articles` and wire it in `NewsSource#build_fetcher` and/or `NewsAggregatorService.default_fetchers`
3. Use consistent `source_type` naming pattern
4. Update category grouping in `articles_helper.rb` if needed

## Production security (CSP, hosts, and rate limiting)

### Content Security Policy

`config/initializers/content_security_policy.rb` enables CSP in **production and test** (not development, so Vite HMR keeps working).

| Directive | Value | Why |
|-----------|--------|-----|
| `script-src` | `'self'` | Vite ships external `type="module"` scripts under `/vite` |
| `style-src` | `'self' 'unsafe-inline'` | Bundled CSS plus React `style={{}}` attributes |
| `connect-src` | `'self'` | Same-origin JSON API (`fetch`) |
| `worker-src` | `'self'` | PWA service worker |

**Nonces are not required** for the current React shell: there are no inline `<script>` tags. Add `content_security_policy_nonce_generator` only if you introduce inline scripts, importmap, or Vite React Refresh tags under an enforcing CSP.

### Host authorization

Production sets `config.hosts` from `APP_HOSTS` (comma-separated; default `app.example.com`) and excludes `/up` from host checks. Kamal injects `APP_HOSTS` in `config/deploy.yml` — keep it aligned with `proxy.host`.

### Rate limiting (Rack::Attack)

`config/initializers/rack_attack.rb` enables throttles in **production and test** (disabled in development). Defaults:

| Rule | Scope | Limit | Notes |
|------|--------|-------|--------|
| Health check | `GET /up` | unlimited | Safelisted for load balancers |
| Global | all requests / IP | 300 / 5 minutes | Soft DoS ceiling |
| Mutations | `POST`/`PATCH`/`PUT`/`DELETE` / IP | 60 / minute | bookmark, dismiss, read, sources |
| Fetch news | `POST /articles/fetch` | 1 / 2 minutes | Separate controller limit (unchanged) |

Exceeded limits return `429` with JSON `{ "error": "Rate limit exceeded. Please try again later." }` and a `Retry-After` header. Override limits with `RACK_ATTACK_GLOBAL_LIMIT`, `RACK_ATTACK_GLOBAL_PERIOD`, `RACK_ATTACK_MUTATE_LIMIT`, and `RACK_ATTACK_MUTATE_PERIOD` (seconds).

### Mutating API authentication

**Decision:** ENV-gated HTTP Basic on mutating actions only. Read endpoints (`GET` articles, bookmarks, sources, etc.) stay public. No multi-user accounts.

| Mode | Behavior |
|------|----------|
| `MUTATING_AUTH_USERNAME` + `MUTATING_AUTH_PASSWORD` unset | Mutations open (local/dev default) |
| Both set | Mutations require HTTP Basic; missing/invalid creds → `401` JSON `{ "error": "Unauthorized" }` |

Protected actions: article fetch/bookmark/dismiss, mark/unmark read, source create/update/destroy.

The React client sends `Authorization: Basic …` from `sessionStorage` when set, and prompts once on a mutating `401`. For public deploys, set both env vars in Kamal secrets (`config/deploy.yml`). Alternative: terminate auth at a reverse proxy and leave app env unset.

## Deployment (Kamal)

CD is implemented as `.github/workflows/deploy.yml` (manual `workflow_dispatch`). The job is a no-op until you opt in — it only runs when the repository variable `KAMAL_DEPLOY_ENABLED` is `true`.

### Prerequisites

1. Set real values in `config/deploy.yml`: `servers.web`, `proxy.host`, and `APP_HOSTS` (must match).
2. Server accepts SSH from the deploy key and can pull from GHCR / run Docker.
3. Configure GitHub:

| Kind | Name | Purpose |
|------|------|---------|
| Variable | `KAMAL_DEPLOY_ENABLED` | Set to `true` to allow the Deploy workflow |
| Variable | `KAMAL_SERVER_HOST` | Host/IP for `ssh-keyscan` (same as `servers.web`) |
| Secret | `SSH_PRIVATE_KEY` | Private key for the deploy user |
| Secret | `RAILS_MASTER_KEY` | Production credentials key |
| Secret | `MUTATING_AUTH_USERNAME` / `MUTATING_AUTH_PASSWORD` | Optional; enable mutating Basic auth |

Images push to `ghcr.io/marcoslorejan/dev-news-aggregator` using `GITHUB_TOKEN`. Use a GitHub Environment named `production` for optional approval gates.

### Run a deploy

1. Ensure CI is green on the commit you intend to ship.
2. Actions → **Deploy** → **Run workflow**.
3. Locally: export registry/SSH-related env vars, then `bundle exec kamal deploy`.

### Rollback

```bash
# List recent app versions on the server
bundle exec kamal app containers

# Roll back to a previous version tag
bundle exec kamal rollback <VERSION>
```

After a bad deploy from Actions, re-run Deploy on a known-good commit, or SSH/local Kamal rollback as above.

### Error monitoring and fetch alerts

Unhandled exceptions and explicit `Rails.error.report` calls are handled by `ErrorReporting::Subscriber` (`config/initializers/error_reporting.rb`):

1. **Structured logs** — JSON lines with `event: "error.reported"` on stdout (visible via `bin/kamal app logs` / `kamal logs`).
2. **Optional webhook** — set `ERROR_WEBHOOK_URL` to a Slack/Discord/generic HTTP endpoint. Posts JSON including a `text` field. Duplicate alerts for the same source + error class are suppressed for 30 minutes.
3. **Fetch failures** — `NewsAggregatorService` reports rescued fetcher errors with `source: "news_fetch"` so they appear even though the job itself does not fail. Per-source status also remains on the Sources page (`FetchRun`).

| ENV | Purpose |
|-----|---------|
| `ERROR_WEBHOOK_URL` | Optional alert webhook (leave unset for log-only) |

No SaaS SDK is required; add Sentry later by installing the gem (it also subscribes to `Rails.error`) if you want a full dashboard.

## Coding guidelines

### General principles

- Follow **SOLID**, **KISS**, and **DRY**
- Use descriptive method and variable names
- Keep methods small and focused on a single responsibility
- Prefer composition over inheritance
- Prefer early returns over ternary operators for better readability
- **Do not add comments to code** — code should be self-documenting through clear naming and structure

### Ruby/Rails conventions

- Follow RuboCop conventions (run `bin/rubocop` to check)
- Use consistent indentation (2 spaces)
- Follow Rails naming conventions
- Use strong parameters in controllers
- Keep controllers thin, models fat (within reason)
- Use services for complex business logic
- Prefer `find_by` over `where.first`
- Use scopes for reusable queries

### Testing standards

- **For every change, create tests** — mandatory, no exceptions
- **Prefer TDD** — write tests first when possible, then implement functionality
- All tests start with `should` (e.g., `test "should create bookmark when valid"`)
- Do not use `send` in tests — test public interface only
- Always prefer fixtures over `create` methods for consistency
- Mock only when necessary (external APIs, slow operations); prefer WebMock/stubs over heavy mocking frameworks
- Do not use comments in tests — test names should be self-descriptive
- Follow RuboCop conventions in test files
- Apply SOLID and KISS principles to test code
- One assertion per concept; multiple assertions per test are acceptable if related
- Use `setup` method for common test data initialization
- Prefer integration tests over unit tests when testing user workflows
- Use `parallelize(workers: :number_of_processors)` in test_helper.rb for faster test runs
- Disable Spring for testing to avoid caching issues
- When adding new models, controllers, or features, create comprehensive test coverage immediately
- Test both happy path and edge cases (error conditions, boundary values, invalid inputs)

### Git commit guidelines

- **Always run tests and RuboCop before committing** — run `bin/rails test` and `bin/rubocop`
- Use conventional commit format (e.g., `feat:`, `fix:`, `test:`, `refactor:`) — enforced by Overcommit commit-msg (`MessageFormat`); see [PRE_COMMIT_HOOKS.md](PRE_COMMIT_HOOKS.md)
- Subject after `type:` must be lowercase (e.g. `feat: add bookmarks`, not `feat: Add bookmarks`)
- One line commit messages only — no body or additional description
- One commit per file (exceptions allowed for large PRs with same context)
- No co-authored comments
- Keep commit messages concise and descriptive
- Commit frequently to save changes — don't wait until everything is perfect
- Push commits regularly to avoid losing work
- Install hooks via `bin/setup` / `.\setup-local-env.ps1`, or manually with `bundle exec overcommit --install` and `bundle exec overcommit --sign`

### GitHub issue and branch workflow

- When creating issues, use `gh` CLI and conventional commits format
- **Always add appropriate labels to issues** using `--label` option with `gh` CLI
- Required issue labels:
  - Type: `feature`, `bug`, `enhancement`, `documentation`, `test`, etc.
  - Priority: `high`, `medium`, `low`
  - Status: `todo`, `in-progress`, `review-needed`, etc.
- Example issue creation: `gh issue create --title "feat: new feature" --body "Description" --label "feature,medium,todo"`
- Use available issue templates when creating new issues
- **When working on an issue, always follow this workflow:**
  1. Create a new branch based on the issue name
  2. Make changes and commit following conventional commits format
  3. Push branch to origin
  4. **Create Pull Request using `gh` CLI — never commit directly to master**
  5. Wait for review/approval before merging
- Branch naming convention: use descriptive names related to the issue (e.g., `fix-ci-bundler-cache`, `feat-deployment-automation`)
- **Example PR workflow:**
  ```bash
  git checkout -b feat-new-feature
  # Make changes...
  git add .
  git commit -m "feat: implement new feature"
  git push origin feat-new-feature
  gh pr create --title "feat: implement new feature" --body "Closes #123"
  ```
