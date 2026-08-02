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

    def hn_item_concurrency
      fetching[:hn_item_concurrency] || 10
    end

    def reddit_subreddits
      Array(config.dig(:apis, :reddit, :subreddits))
    end

    def interests
      Array(config[:interests])
    end

    def reddit_min_request_interval_seconds
      config.dig(:apis, :reddit, :min_request_interval_seconds) || 2.5
    end

    def reddit_rate_limit_max_retries
      config.dig(:apis, :reddit, :rate_limit_max_retries) || 4
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

    def youtube_channels
      Array(config.dig(:apis, :youtube, :channels)).filter_map { |entry|
        next if entry.blank?

        channel = entry.is_a?(Hash) ? entry : { channel_id: entry }
        channel_id = channel[:channel_id].presence || channel["channel_id"].presence
        next if channel_id.blank?

        {
          channel_id: channel_id.to_s,
          name: (channel[:name] || channel["name"]).presence || channel_id.to_s
        }
      }
    end

    def youtube_min_request_interval_seconds
      config.dig(:apis, :youtube, :min_request_interval_seconds) || 2.0
    end

    def youtube_rate_limit_max_retries
      config.dig(:apis, :youtube, :rate_limit_max_retries) || 4
    end

    def youtube_feed_base_url
      config.dig(:apis, :youtube, :feed_base_url) || "https://www.youtube.com/feeds/videos.xml"
    end

    def youtube_enrich_with_api?
      flag = config.dig(:apis, :youtube, :enrich_with_api)
      flag.nil? ? true : ActiveModel::Type::Boolean.new.cast(flag)
    end

    def youtube_enrich_batch_size
      size = config.dig(:apis, :youtube, :enrich_batch_size) || 50
      [ size.to_i, 1 ].max.clamp(1, 50)
    end

    def youtube_enrich_max_per_run
      max = config.dig(:apis, :youtube, :enrich_max_per_run) || 100
      [ max.to_i, 0 ].max
    end

    def youtube_max_duration_seconds
      config.dig(:apis, :youtube, :max_duration_seconds) || 1200
    end
  end
end
