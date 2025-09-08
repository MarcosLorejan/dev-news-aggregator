class NewsAggregatorService
  def self.fetch_all_news
    new.fetch_all_news
  end

  def initialize
    @fetchers = [
      NewsFetchers::HackerNewsFetcher.new,
      NewsFetchers::DevToFetcher.new,
      NewsFetchers::RedditFetcher.new(subreddit: 'programming'),
      NewsFetchers::RedditFetcher.new(subreddit: 'webdev'),
      NewsFetchers::RedditFetcher.new(subreddit: 'javascript')
    ]
    @all_articles = []
  end

  def fetch_all_news
    Rails.logger.info "Starting news aggregation from all sources..."
    start_time = Time.current

    @fetchers.each do |fetcher|
      begin
        articles = fetcher.fetch_articles
        @all_articles.concat(articles)
        Rails.logger.info "#{fetcher.class.name}: fetched #{articles.count} articles"
      rescue StandardError => e
        Rails.logger.error "Error with #{fetcher.class.name}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    end_time = Time.current
    duration = (end_time - start_time).round(2)

    Rails.logger.info "News aggregation completed in #{duration}s. Total articles processed: #{@all_articles.count}"
    
    {
      articles_count: @all_articles.count,
      duration: duration,
      sources: @fetchers.map { |f| f.class.name.demodulize },
      timestamp: end_time
    }
  end
end
