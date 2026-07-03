# Dev News Aggregator

A Rails application that aggregates developer news from Hacker News, Dev.to, and Reddit programming communities with automated fetching and bookmarking features.

## Features

- **Multi-source aggregation**: Fetches from 12+ sources including Hacker News, Dev.to, and programming subreddits
- **Article bookmarking**: Save articles for later reading with category filtering  
- **Automated updates**: Hourly fetching during business hours via cron jobs
- **Responsive interface**: Clean web UI with source-based filtering

## Quick Start

```bash
# Install dependencies
bundle install

# Start PostgreSQL container
sudo docker-compose up -d

# Setup database
bin/rails db:migrate
bin/rails db:seed

# Fetch initial news
bin/rails runner "NewsAggregatorService.fetch_all_news"

# Start server
bin/rails server
```

Visit http://localhost:3000

## Tech Stack

- **Backend**: Rails 8.0.2
- **Database**: PostgreSQL (Docker)
- **Styling**: Tailwind CSS  
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

# Clean old articles (7+ days)
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

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for development guidelines and [docs/REPO_STRUCTURE.md](docs/REPO_STRUCTURE.md) for the repository map (keep it updated when structure changes).

### Pre-commit Hooks

This project uses Overcommit for automated code quality checks before commits. See [docs/PRE_COMMIT_HOOKS.md](docs/PRE_COMMIT_HOOKS.md) for setup instructions.

```bash
# One-time setup
bundle exec overcommit --install
bundle exec overcommit --sign
```

## License

MIT License
