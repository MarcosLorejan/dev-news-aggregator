# Development Guide

Project-specific commands, architecture, and conventions for dev-news-aggregator.

For the directory map, see [REPO_STRUCTURE.md](REPO_STRUCTURE.md). **Update that file whenever you change project structure** (new folders, models, routes, migrations, etc.).

## Development commands

### Setup & database

```bash
# Install dependencies
bundle install

# Start PostgreSQL container
sudo docker-compose up -d

# Setup database
bin/rails db:migrate
bin/rails db:seed

# Initial news fetch
bin/rails runner "NewsAggregatorService.fetch_all_news"
```

### Running the application

```bash
# Start Rails server
bin/rails server

# Run in development mode
bin/dev

# Access application at http://localhost:3000
```

### News operations

```bash
# Fetch news from all sources
bin/rails news:fetch

# Show latest 10 articles
bin/rails news:latest

# Clean old articles (uses retention from config/news_aggregator.yml)
bin/rails news:clean

# Manual service call
bin/rails runner "NewsAggregatorService.fetch_all_news"
```

### Testing

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/article_test.rb

# Run specific test
bin/rails test test/controllers/articles_controller_test.rb -n test_index
```

### Code quality

```bash
# Run RuboCop linter
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -a

# Security audit
bin/brakeman
```

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
- `NewsSource`: Optional database-backed source registry; when enabled records exist, they override the YAML default fetcher list

**Scheduled jobs**: Uses `whenever` gem to run `news:fetch` hourly during business hours (9 AM - 6 PM) and `news:clean` daily at 2 AM. Logs to `log/cron.log`.

### Key design patterns

**Service-oriented architecture**: Business logic separated into service classes rather than fat models. Each news source has its own fetcher service.

**Fail-safe aggregation**: If one news source fails, others continue processing. Errors are logged but don't stop the entire aggregation process.

**Idempotent updates**: Articles use `find_or_initialize_by(external_id, source_type)` to prevent duplicates while allowing updates to existing articles.

**Rate limiting awareness**: Per-source article limits come from `NewsAggregatorConfig.max_articles_per_source` (see `config/news_aggregator.yml`). Includes proper error handling for API failures.

### File structure

```
app/
  controllers/articles_controller.rb    # Main web interface
  models/
    article.rb                          # Article data model
    news_aggregator_config.rb           # YAML config loader for news fetching
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

**Reddit**: Multiple instances for different subreddits. Each subreddit is treated as a separate source type in the database.

### Database schema

Articles table uses generic fields to accommodate all news sources:
- `source_type`: String identifier (hacker_news, dev_to, reddit_programming, etc.)
- `external_id`: Source-specific unique identifier
- `score`: Votes/reactions from source (HN score, Dev.to reactions, Reddit upvotes)
- `comment_count`: Source-specific comment counts

### Environment configuration

Uses Docker Compose for PostgreSQL with environment variables:
- `POSTGRES_USER`: devnews
- `POSTGRES_PASSWORD`: password
- `POSTGRES_DB`: dev_news_aggregator

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
- Mock only when necessary (external APIs, slow operations) and use mocha gem for mocking
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
- Use conventional commit format (e.g., `feat:`, `fix:`, `test:`, `refactor:`)
- One line commit messages only — no body or additional description
- One commit per file (exceptions allowed for large PRs with same context)
- No co-authored comments
- Keep commit messages concise and descriptive
- Commit frequently to save changes — don't wait until everything is perfect
- Push commits regularly to avoid losing work

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
