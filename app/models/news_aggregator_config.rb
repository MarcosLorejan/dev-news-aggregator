module NewsAggregatorConfig
  class << self
    def config
      @config ||= Rails.application.config_for(:news_aggregator).deep_symbolize_keys
    end

    def reset!
      @config = nil
    end

    def fetching
      config.fetch(:fetching, {})
    end

    def retention_days
      config.dig(:retention, :article_retention_days) || 30
    end

    def max_articles_per_source
      fetching[:max_articles_per_source] || 30
    end

    def request_timeout
      fetching[:request_timeout] || 30
    end

    def max_retries
      fetching[:max_retries] || 3
    end

    def reddit_subreddits
      Array(config.dig(:apis, :reddit, :subreddits))
    end

    def hacker_news_base_url
      config.dig(:apis, :hacker_news, :base_url)
    end

    def devto_base_url
      config.dig(:apis, :devto, :base_url)
    end

    def reddit_base_url
      config.dig(:apis, :reddit, :base_url)
    end
  end
end
