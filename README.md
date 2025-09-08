# Dev News Aggregator

A Ruby on Rails application that aggregates daily news from popular developer sites including Hacker News, Dev.to, and Reddit programming communities.

## Features

- **Multi-source news aggregation**: Fetches articles from Hacker News, Dev.to, and multiple programming subreddits
- **Clean web interface**: Responsive design with source-based filtering
- **Scheduled updates**: Daily automated news fetching via cron jobs
- **PostgreSQL database**: Stores articles with metadata and source tracking
- **API integration**: Uses official APIs instead of web scraping for reliability

## Tech Stack

- **Backend**: Ruby on Rails 8.0.2
- **Database**: PostgreSQL (via Docker)
- **Styling**: Tailwind CSS
- **Job scheduling**: Whenever gem with cron
- **HTTP requests**: HTTParty gem
- **Containerization**: Docker Compose for PostgreSQL

## Setup Instructions

### Prerequisites

- Ruby (version compatible with Rails 8.0.2)
- Docker and Docker Compose
- Git

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd dev-news-aggregator
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Start PostgreSQL with Docker**:
   ```bash
   sudo docker-compose up -d
   ```

4. **Set up the database**:
   ```bash
   bin/rails db:migrate
   ```

5. **Seed news sources** (optional):
   ```bash
   bin/rails db:seed
   ```

6. **Fetch initial news data**:
   ```bash
   bin/rails runner "NewsAggregatorService.fetch_all_news"
   ```

7. **Start the Rails server**:
   ```bash
   bin/rails server
   ```

8. **Visit the application**:
   Open http://localhost:3000 in your browser

## Usage

### Manual News Fetching

You can manually trigger news fetching using rake tasks:

```bash
# Fetch news from all sources
bin/rails news:fetch

# Show latest articles
bin/rails news:latest

# Clean old articles (older than 30 days)
bin/rails news:clean
```

### Scheduled Jobs

The application is configured to automatically fetch news daily at 8 AM. To set up the cron job:

```bash
# Update crontab with scheduled jobs
whenever --update-crontab

# View current cron schedule
crontab -l
```

### Web Interface

- **Home page**: Shows latest 50 articles grouped by source
- **Article filtering**: Click source buttons to filter articles
- **Article details**: Click article titles to view full details
- **Responsive design**: Works on desktop and mobile devices

## News Sources

The application fetches news from:

1. **Hacker News**: Top stories from Y Combinator's news site
2. **Dev.to**: Latest articles from the developer community platform  
3. **Reddit**: Posts from programming-related subreddits:
   - r/programming
   - r/webdev
   - r/javascript

## Database Schema

### NewsSource
- `name`: Source name (e.g., "Hacker News", "Dev.to")
- `url`: Source base URL
- `api_endpoint`: API endpoint for fetching articles

### Article
- `title`: Article headline
- `url`: Link to full article
- `summary`: Article excerpt or description
- `published_at`: When article was published
- `external_id`: Unique ID from source API
- `news_source_id`: Foreign key to NewsSource
- `score`: Article score/votes (if available)
- `comments_count`: Number of comments (if available)

## Configuration

### Environment Variables

The application uses the following environment variables for database configuration:

- `POSTGRES_USER`: PostgreSQL username (default: devnews)
- `POSTGRES_PASSWORD`: PostgreSQL password (default: password)
- `POSTGRES_DB`: Database name (default: dev_news_aggregator)

### Docker Configuration

PostgreSQL runs in a Docker container with:
- Port: 5432
- Volume: `postgres_data` for data persistence
- Initialization script: `init.sql` for user setup

## Development

### Adding New News Sources

1. Create a new fetcher class in `app/services/news_fetchers/`
2. Inherit from `NewsFetchers::BaseFetcher`
3. Implement the `fetch_articles` method
4. Add the fetcher to `NewsAggregatorService#initialize`

### API Rate Limiting

The application respects API rate limits:
- Includes proper error handling for API failures
- Logs all fetching activities
- Continues processing other sources if one fails

## Deployment

For production deployment:

1. Set up a PostgreSQL database
2. Configure environment variables
3. Run database migrations
4. Set up cron jobs with `whenever`
5. Configure a web server (Nginx + Puma recommended)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is open source and available under the MIT License.
