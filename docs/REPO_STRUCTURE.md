# Repository Structure

Living map of this codebase. **Keep this file in sync with the repo** — see [Maintenance](#maintenance) below.

Last updated: 2026-07-03

## Maintenance

Update this file in the **same PR or commit** whenever you change project structure, including:

- New, renamed, moved, or removed directories or top-level files
- New models, controllers, services, jobs, or fetchers
- New migrations or meaningful schema changes
- New routes or major feature areas
- New config files that define app behavior
- New docs, CI workflows, or tooling entry points

**Do not** update for trivial edits (bug fixes, copy changes, test-only changes inside existing files).

When updating:

1. Adjust the tree and tables below to match reality.
2. Add or revise the one-line purpose for anything new.
3. Set **Last updated** at the top to today's date.

Agents and contributors: if you make a structural change and this file was not updated, update it before finishing the task (or flag it to the user).

## Overview

Rails 8 news aggregator with a React (Vite) frontend, PostgreSQL, and scheduled news fetching from Hacker News, Dev.to, and Reddit.

```
dev-news-aggregator/
├── app/                    # Application code (MVC, services, jobs, frontend)
├── bin/                    # Executables (rails, dev, jobs, rubocop, brakeman, …)
├── config/                 # Rails and app configuration
├── db/                     # Migrations, schema, seeds
├── docs/                   # Project documentation
├── lib/                    # Rake tasks and non-autoloaded code
├── public/                 # Static assets and error pages
├── test/                   # Minitest suite (models, controllers, system, integration)
├── .github/                # CI/CD and Dependabot
├── docker-compose.yml      # Local PostgreSQL
├── Dockerfile              # Container build
├── Gemfile                 # Ruby dependencies
├── package.json            # Node dependencies (Vite, React)
└── vite.config.ts          # Vite bundler config
```

## `app/`

| Path | Purpose |
|------|---------|
| `app/controllers/` | HTTP layer — articles, bookmarks, read/dismissed lists |
| `app/models/` | ActiveRecord models |
| `app/services/` | Business logic — news aggregation orchestration |
| `app/services/news_fetchers/` | Per-source API fetchers (HN, Dev.to, Reddit) |
| `app/jobs/` | Background jobs (e.g. permanent dismissal) |
| `app/helpers/` | View helpers (categories, formatting) |
| `app/views/` | ERB templates |
| `app/frontend/` | React app (Vite entrypoint + components) |
| `app/javascript/` | Stimulus controllers and legacy JS hooks |
| `app/assets/stylesheets/` | CSS |
| `app/mailers/` | Action Mailer base |

### Controllers

| File | Responsibility |
|------|----------------|
| `articles_controller.rb` | Article list/show, bookmark, dismiss actions |
| `bookmarks_controller.rb` | Saved articles index |
| `read_articles_controller.rb` | Mark articles as read |
| `dismissed_articles_controller.rb` | Dismissed and recently dismissed lists |

### Models

| File | Table | Purpose |
|------|-------|---------|
| `article.rb` | `articles` | Aggregated news item from any source |
| `bookmark.rb` | `bookmarks` | User-saved article |
| `read_article.rb` | `read_articles` | Article marked as read |
| `dismissed_article.rb` | `dismissed_articles` | Article hidden from feed |
| `news_source.rb` | `news_sources` | Optional DB-backed source registry; overrides YAML defaults when enabled |
| `news_aggregator_config.rb` | — | Loads `config/news_aggregator.yml` (limits, retention, subreddits) |

### Services

| File | Purpose |
|------|---------|
| `news_aggregator_service.rb` | Runs all fetchers, handles errors, aggregates results |
| `news_fetchers/base_fetcher.rb` | Abstract fetcher — fetch, transform, upsert article |
| `news_fetchers/hacker_news_fetcher.rb` | Hacker News Firebase API |
| `news_fetchers/dev_to_fetcher.rb` | Dev.to REST API |
| `news_fetchers/reddit_fetcher.rb` | Reddit API (one instance per subreddit) |

### Jobs

| File | Purpose |
|------|---------|
| `make_dismissal_permanent_job.rb` | Converts temporary dismissals to permanent |
| `fetch_news_job.rb` | Fetches news from all sources asynchronously |

### Frontend

| Path | Purpose |
|------|---------|
| `app/frontend/entrypoints/application.tsx` | Vite/React mount point |
| `app/frontend/components/App.tsx` | Root React component |

## `config/`

| File | Purpose |
|------|---------|
| `routes.rb` | URL routing |
| `database.yml` | PostgreSQL connection (primary + queue DB in dev/production) |
| `schedule.rb` | Cron definitions (`whenever` gem) |
| `news_aggregator.yml` | Fetch limits, retention, subreddit list, API endpoints |
| `queue.yml` | Solid Queue worker and dispatcher settings |
| `recurring.yml` | Solid Queue recurring task schedule |
| `deploy.yml` | Kamal deployment |
| `vite.json` | Vite-Rails integration |
| `environments/` | Per-env Rails settings (development, test, production) |
| `initializers/` | Boot-time Ruby configuration |

## `db/`

| Path | Purpose |
|------|---------|
| `migrate/` | Schema migrations |
| `schema.rb` | Primary database schema (generated) |
| `queue_schema.rb` | Solid Queue database schema (loaded into queue DB) |
| `queue_migrate/` | Queue DB migrations path (schema loaded via `db:prepare`) |
| `seeds.rb` | Seed data |

### Migrations (in order)

| Migration | Creates |
|-----------|---------|
| `create_news_sources` | `news_sources` |
| `create_articles` | `articles` |
| `create_bookmarks` | `bookmarks` |
| `create_read_articles` | `read_articles` |
| `create_dismissed_articles` | `dismissed_articles` |

## `lib/`

| Path | Purpose |
|------|---------|
| `lib/tasks/news.rake` | `news:fetch`, `news:latest`, `news:clean` rake tasks |

## `test/`

| Path | Purpose |
|------|---------|
| `test/models/` | Model unit tests |
| `test/controllers/` | Controller tests |
| `test/services/` | Service and fetcher tests |
| `test/jobs/` | Job tests |
| `test/helpers/` | Helper tests |
| `test/integration/` | Multi-step workflow tests |
| `test/system/` | Browser/system tests (Capybara) |
| `test/fixtures/` | YAML test data |

## `docs/`

| File | Purpose |
|------|---------|
| `DEVELOPMENT.md` | Commands, architecture, coding and git conventions |
| `REPO_STRUCTURE.md` | This file — directory map and maintenance rules |
| `PRE_COMMIT_HOOKS.md` | Overcommit setup and usage |
| `REACT_SETUP.md` | React/Vite frontend setup |

## `.github/`

| Path | Purpose |
|------|---------|
| `workflows/ci.yml` | CI pipeline (tests, lint, security) |
| `workflows/dependabot-auto-merge.yml` | Auto-merge for patch/minor Dependabot PRs |
| `dependabot.yml` | Dependency update schedule |
| `ISSUE_TEMPLATE/` | GitHub issue templates |

## Key root files

| File | Purpose |
|------|---------|
| `README.md` | Project overview and quick start |
| `Gemfile` / `Gemfile.lock` | Ruby gems |
| `package.json` / `package-lock.json` | Node packages |
| `docker-compose.yml` | Local PostgreSQL container |
| `Dockerfile` | Production/container image |
| `.overcommit.yml` | Git hook configuration |
| `.rubocop.yml` | Ruby style rules |
| `tsconfig.json` | TypeScript config for frontend |

## Routes (summary)

| Path | Controller#action |
|------|-------------------|
| `/` | `articles#index` |
| `/articles/:id` | `articles#show` |
| `/bookmarks` | `bookmarks#index` |
| `/read` | `read_articles#index` |
| `/dismissed` | `dismissed_articles#index` |
| `/recently_dismissed` | `dismissed_articles#recently_dismissed` |
| `/up` | Rails health check |

See `config/routes.rb` for member routes (bookmark, dismiss, mark as read, etc.).
