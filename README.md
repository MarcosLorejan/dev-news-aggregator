# Dev News Aggregator

A Rails application that aggregates developer news from Hacker News, Dev.to, and Reddit programming communities with automated fetching and bookmarking features.

## Features

- **Multi-source aggregation**: Fetches from 12+ sources including Hacker News, Dev.to, and programming subreddits
- **Article bookmarking**: Save articles for later reading with category filtering  
- **Automated updates**: Hourly fetching during business hours via cron jobs
- **Responsive interface**: React SPA with source-based filtering and Vite HMR in development

## Quick Start

```bash
# Install dependencies
bundle install

# Copy the environment template (holds the local database credentials)
cp .env.example .env

# Start PostgreSQL only (Rails/Vite run on the host; see below)
docker compose up -d

# Setup database
bin/rails db:migrate
bin/rails db:seed

# Fetch initial news
bin/rails runner "NewsAggregatorService.fetch_all_news"

# Full stack: Vite (HMR) + Rails — two terminals
npm install
npm run dev          # terminal 1, port 3036
bin/rails server     # terminal 2, port 3000

# Windows alternative (starts both):
# .\dev.ps1
```

Visit http://localhost:3000.

`bin/dev` and bare `bin/rails server` start **Rails only** (no Vite). For React hot reload you need `npm run dev` as well, or `.\dev.ps1` on Windows. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) and [docs/REACT_SETUP.md](docs/REACT_SETUP.md).

## Tech Stack

- **Backend**: Rails 8.1 on Ruby 3.3 (see `.ruby-version`)
- **Database**: PostgreSQL (Docker)
- **Frontend**: React + Vite; **Styling**: Tailwind CSS (CDN)  
- **Scheduling**: Whenever gem with cron
- **HTTP**: HTTParty gem

## News Sources

Fetches from 12+ sources including:
- **Hacker News**: Top stories
- **Dev.to**: Developer community articles
- **Reddit**: Programming subreddits (ruby, rust, javascript, programming, webdev, netsec, cybersecurity, technology, MachineLearning, artificial, LocalLLaMA)

## Commands

```bash
# Fetch news manually
bin/rails news:fetch

# Show latest 10 articles
bin/rails news:latest

# Clean old articles (retention from config/news_aggregator.yml)
bin/rails news:clean

# Setup cron jobs
whenever --update-crontab

# Run tests
bin/rails test

# Code quality
bin/rubocop
bin/brakeman
```

## Automated Dependency Management

This project uses **Dependabot** with automated merge capabilities:

- **Patch & Minor Updates**: Automatically merged after all CI checks pass
- **Major Updates**: Require manual review and approval
- **CI Integration**: Auto-merge only triggers when all tests, linting, and security scans succeed
- **Safety First**: Major version updates are flagged with warnings for manual review

The automation runs on all Dependabot PRs for:
- Ruby dependencies (Bundler)
- GitHub Actions
- Docker images

No manual intervention needed for routine security patches and minor updates!

## Production security

For public deployments, enable mutating API HTTP Basic via `MUTATING_AUTH_USERNAME` / `MUTATING_AUTH_PASSWORD`, plus CSP, `APP_HOSTS`, and Rack::Attack throttles. Reads stay public; mutations return `401` without credentials. Details: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#production-security-csp-hosts-and-rate-limiting).

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for the contributor entry point, [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for development guidelines, and [docs/REPO_STRUCTURE.md](docs/REPO_STRUCTURE.md) for the repository map (keep it updated when structure changes).

### Pre-commit Hooks

This project uses Overcommit for automated code quality checks before commits. See [docs/PRE_COMMIT_HOOKS.md](docs/PRE_COMMIT_HOOKS.md) for setup instructions.

```bash
# One-time setup
bundle exec overcommit --install
bundle exec overcommit --sign
```

## License

MIT License
