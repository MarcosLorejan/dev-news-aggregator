class NewsAggregatorService
  def self.fetch_all_news
    new.fetch_all_news
  end

  def initialize
    @fetchers = self.class.build_fetchers
    @all_articles = []
  end

  def self.build_fetchers
    if NewsSource.enabled.exists?
      NewsSource.enabled.order(:source_type, :name).filter_map(&:build_fetcher)
    else
      default_fetchers
    end
  end

  def self.default_fetchers
    fetchers = [
      NewsFetchers::HackerNewsFetcher.new,
      NewsFetchers::DevToFetcher.new
    ]

    NewsAggregatorConfig.reddit_subreddits.each do |subreddit|
      fetchers << NewsFetchers::RedditFetcher.new(subreddit: subreddit)
    end

    fetchers
  end

  def fetch_all_news
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    mutex = Mutex.new

    threads = @fetchers.map do |fetcher|
      Thread.new do
        Rails.application.executor.wrap do
          ActiveRecord::Base.connection_pool.with_connection do
            articles = run_fetcher(fetcher)
            mutex.synchronize { @all_articles.concat(articles) }
          end
        end
      end
    end

    threads.each(&:join)

    duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)
    finished_at = Time.current

    NewsFetchObservability.log_aggregation_completed(
      articles_count: @all_articles.count,
      duration_seconds: duration,
      source_count: @fetchers.length
    )

    {
      articles_count: @all_articles.count,
      duration: duration,
      sources: @fetchers.map { |f| f.class.name.demodulize },
      timestamp: finished_at
    }
  end

  private

  def run_fetcher(fetcher)
    source_key = fetcher_source_key(fetcher)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    articles = fetcher.fetch_articles
    duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)

    FetchRun.record_outcome(
      source_key: source_key,
      status: "success",
      articles_count: articles.count,
      duration_seconds: duration
    )

    articles
  rescue StandardError => e
    duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)

    FetchRun.record_outcome(
      source_key: source_key,
      status: "failure",
      duration_seconds: duration,
      error: e
    )

    Rails.logger.error e.backtrace.join("\n")
    []
  end

  def fetcher_source_key(fetcher)
    return fetcher.source_key if fetcher.respond_to?(:source_key)

    fetcher.class.name.demodulize.underscore
  end
end
