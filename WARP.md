# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Setup & Database
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

### Running the Application
```bash
# Start Rails server
bin/rails server

# Run in development mode
bin/dev

# Access application at http://localhost:3000
```

### News Operations
```bash
# Fetch news from all sources
bin/rails news:fetch

# Show latest 10 articles
bin/rails news:latest

# Clean old articles (7+ days)
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

### Code Quality
```bash
# Run RuboCop linter
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -a

# Security audit
bin/brakeman
```

### Cron Jobs
```bash
# Update crontab with scheduled jobs
whenever --update-crontab

# View current cron schedule  
crontab -l

# Clear crontab
whenever --clear-crontab
```

## Architecture Overview

### Core Components

**NewsAggregatorService**: Central orchestrator that coordinates all news fetchers. Initializes fetchers for Hacker News, Dev.to, and multiple Reddit subreddits covering programming languages (Ruby, Rust, JavaScript), web development, cybersecurity, AI/ML, and general tech. Handles error logging and aggregates results.

**Fetcher Architecture**: Modular fetcher system with `NewsFetchers::BaseFetcher` as the abstract base class. Each fetcher (HackerNews, DevTo, Reddit) inherits and implements `fetch_articles`. Common pattern: fetch from API, transform data, call `create_or_update_article`.

**Data Models**:
- `Article`: Stores aggregated news with unified schema (title, url, published_at, description, external_id, source_type, score, comment_count)
- `Bookmark`: Tracks bookmarked articles for personal reading list functionality
- `NewsSource`: Configuration table for news sources (currently unused in favor of hard-coded fetchers)

**Scheduled Jobs**: Uses `whenever` gem to run `news:fetch` hourly during business hours (9 AM - 6 PM) and `news:clean` daily at 2 AM. Logs to `log/cron.log`.

### Key Design Patterns

**Service-Oriented Architecture**: Business logic separated into service classes rather than fat models. Each news source has its own fetcher service.

**Fail-Safe Aggregation**: If one news source fails, others continue processing. Errors are logged but don't stop the entire aggregation process.

**Idempotent Updates**: Articles use `find_or_initialize_by(external_id, source_type)` to prevent duplicates while allowing updates to existing articles.

**Rate Limiting Awareness**: Limits API calls (e.g., first 30 HN stories) and includes proper error handling for API failures.

### File Structure

```
app/
  controllers/articles_controller.rb    # Main web interface
  models/article.rb                     # Article data model
  services/
    news_aggregator_service.rb          # Main orchestrator
    news_fetchers/
      base_fetcher.rb                   # Abstract fetcher base class
      hacker_news_fetcher.rb            # HN API integration
      dev_to_fetcher.rb                 # Dev.to API integration  
      reddit_fetcher.rb                 # Reddit API integration
lib/tasks/news.rake                     # Rake tasks for news operations
config/schedule.rb                      # Cron job definitions
```

### API Integration Details

**Hacker News**: Uses Firebase API (`hacker-news.firebaseio.com/v0`). Fetches top stories, then individual story details. Filters out Ask HN posts without URLs.

**Dev.to**: Uses REST API (`dev.to/api/articles`) with query params for pagination and filtering by top posts from last 7 days.

**Reddit**: Multiple instances for different subreddits. Each subreddit is treated as a separate source type in the database.

### Database Schema

Articles table uses generic fields to accommodate all news sources:
- `source_type`: String identifier (hacker_news, dev_to, reddit_programming, etc.)
- `external_id`: Source-specific unique identifier 
- `score`: Votes/reactions from source (HN score, Dev.to reactions, Reddit upvotes)
- `comment_count`: Source-specific comment counts

### Environment Configuration

Uses Docker Compose for PostgreSQL with environment variables:
- `POSTGRES_USER`: devnews
- `POSTGRES_PASSWORD`: password  
- `POSTGRES_DB`: dev_news_aggregator

### Key Features

**Article Bookmarking**: Users can bookmark articles for later reading. Bookmarks are displayed in a dedicated reading list with category filtering.

**Category Filtering**: Articles are grouped into logical categories (Programming Languages, Web Development, Security, AI & Machine Learning, General Tech) for easier browsing.

**Multi-Source Aggregation**: Fetches from 12+ different sources including:
- Hacker News (hacker_news)
- Dev.to (dev_to) 
- Reddit subreddits: ruby, rust, javascript, programming, webdev, netsec, cybersecurity, technology, MachineLearning, artificial, LocalLLaMA

### Key Features

**Article Bookmarking**: Users can bookmark articles for later reading. Bookmarks are displayed in a dedicated reading list with category filtering.

**Category Filtering**: Articles are grouped into logical categories (Programming Languages, Web Development, Security, AI & Machine Learning, General Tech) for easier browsing.

**Multi-Source Aggregation**: Fetches from 12+ different sources including:
- Hacker News (hacker_news)
- Dev.to (dev_to) 
- Reddit subreddits: ruby, rust, javascript, programming, webdev, netsec, cybersecurity, technology, MachineLearning, artificial, LocalLLaMA

### Adding New News Sources

1. Create fetcher in `app/services/news_fetchers/` inheriting from `BaseFetcher`
2. Implement `fetch_articles` method
3. Add fetcher instance to `NewsAggregatorService#initialize`
4. Use consistent `source_type` naming pattern
5. Update category grouping in `articles_helper.rb` if needed

## Coding Guidelines

### General Principles
- Follow SOLID principles (Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion)
- Follow KISS convention (Keep It Simple, Stupid)
- Follow DRY principle (Don't Repeat Yourself)
- Use descriptive method and variable names
- Keep methods small and focused on a single responsibility
- Prefer composition over inheritance
- Prefer early returns over ternary operators for better readability

### Ruby/Rails Conventions
- Follow RuboCop conventions (run `bin/rubocop` to check)
- Use consistent indentation (2 spaces)
- Follow Rails naming conventions
- Use strong parameters in controllers
- Keep controllers thin, models fat (within reason)
- Use services for complex business logic
- Prefer `find_by` over `where.first`
- Use scopes for reusable queries

### Testing Standards
- All tests start with 'should' (e.g., `test "should create bookmark when valid"`) 
- Do not use `send` in tests - test public interface only
- Always prefer fixtures over `create` methods for consistency
- Mock only when necessary (external APIs, slow operations) and use mocha gem for mocking
- Do not use comments in tests - test names should be self-descriptive
- Follow RuboCop conventions in test files
- Apply SOLID and KISS principles to test code
- One assertion per concept, multiple assertions per test are acceptable if related
- Use `setup` method for common test data initialization
- Prefer integration tests over unit tests when testing user workflows
- Use `parallelize(workers: :number_of_processors)` in test_helper.rb for faster test runs
- Disable Spring for testing to avoid caching issues

### Git Commit Guidelines
- Use conventional commit format (e.g., `feat:`, `fix:`, `test:`, `refactor:`)
- One line commit messages only - no body or additional description
- One commit per file (exceptions allowed for large PRs with same context)
- No co-authored comments
- Keep commit messages concise and descriptive
- Commit frequently to save changes - don't wait until everything is perfect
- Push commits regularly to avoid losing work
