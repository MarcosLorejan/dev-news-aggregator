# Opt-in YouTube search.list discovery driven by enabled KeywordFilter terms.
# Enforces a hard daily call budget and a per-filter minimum interval so the
# expensive search quota bucket (~100 units/call) is not exhausted by hourly fetches.
class YoutubeKeywordDiscovery
  include HTTParty

  API_URL = "https://www.googleapis.com/youtube/v3/search"
  SOURCE_KEY_PREFIX = "youtube_search_".freeze
  CACHE_KEY_PREFIX = "youtube_search_api_calls:".freeze

  class << self
    def run!
      new.run!
    end

    def api_key
      ENV["YOUTUBE_API_KEY"].presence
    end

    def enabled?
      NewsAggregatorConfig.youtube_search_enabled? && api_key.present?
    end

    def source_key_for(filter)
      "#{SOURCE_KEY_PREFIX}#{filter.slug}"
    end

    def daily_calls_cache_key(date = Time.current.utc.to_date)
      "#{CACHE_KEY_PREFIX}#{date.iso8601}"
    end

    # Overridable so tests can use a MemoryStore (Rails test env uses null_store).
    attr_writer :call_store

    def call_store
      @call_store || Rails.cache
    end

    def reset_call_store!
      @call_store = nil
    end
  end

  def run!
    unless self.class.enabled?
      Rails.logger.info "YouTube keyword discovery skipped (disabled or no API key)"
      return { created: 0, searched: 0, skipped: true }
    end

    created = 0
    searched = 0
    skipped_budget = false

    KeywordFilter.enabled.ordered.each do |filter|
      if remaining_budget <= 0
        skipped_budget = true
        Rails.logger.info "YouTube keyword discovery stopping: daily search budget exhausted"
        break
      end

      next if too_soon?(filter)

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        count = discover_for(filter)
        created += count
        searched += 1
        FetchRun.record_outcome(
          source_key: self.class.source_key_for(filter),
          status: "success",
          articles_count: count,
          duration_seconds: elapsed(started)
        )
      rescue StandardError => e
        Rails.error.report(e, handled: true, context: {
          service: "YoutubeKeywordDiscovery",
          filter: filter.slug
        })
        Rails.logger.error "YouTube search for #{filter.slug} failed: #{e.class}: #{e.message}"
        FetchRun.record_outcome(
          source_key: self.class.source_key_for(filter),
          status: "failure",
          articles_count: 0,
          duration_seconds: elapsed(started),
          error: e
        )
        break if quota_exhausted_error?(e)
      end
    end

    { created: created, searched: searched, skipped: false, budget_exhausted: skipped_budget }
  end

  private

  def discover_for(filter)
    terms = Array(filter.terms).map(&:to_s).map(&:strip).reject(&:blank?)
    return 0 if terms.empty?

    payload = search_videos(query: terms.join("|"), filter: filter)
    consume_call!
    items = payload.is_a?(Hash) ? Array(payload["items"]) : []

    items.count { |item| create_article_from_search_item(item, filter) }
  end

  def create_article_from_search_item(item, filter)
    video_id = item.dig("id", "videoId").presence
    return false if video_id.blank?

    # Prefer the channel-feed row when the same video was already ingested.
    if Article.exists?(external_id: video_id)
      Rails.logger.debug { "Skipping YouTube search hit #{video_id} (already ingested)" }
      return false
    end

    snippet = item["snippet"] || {}
    thumbnails = snippet["thumbnails"] || {}
    thumbnail = thumbnails.dig("high", "url") ||
                thumbnails.dig("medium", "url") ||
                thumbnails.dig("default", "url")

    published_at = begin
      Time.iso8601(snippet["publishedAt"])
    rescue ArgumentError, TypeError
      Time.current
    end

    article = Article.new(
      title: snippet["title"].presence || "YouTube video #{video_id}",
      url: "https://www.youtube.com/watch?v=#{video_id}",
      description: snippet["description"].presence,
      external_id: video_id,
      source_type: self.class.source_key_for(filter),
      published_at: published_at,
      content_type: "video",
      thumbnail_url: YoutubeThumbnail.preferred_url(thumbnail, video_id: video_id),
      author: snippet["channelTitle"].presence,
      score: 0,
      comment_count: 0
    )

    unless article.save
      Rails.logger.warn(
        "Skipping invalid YouTube search video #{video_id}: #{article.errors.full_messages.join(', ')}"
      )
      return false
    end

    Rails.logger.info "Created YouTube search video: #{article.title}"
    true
  rescue StandardError => e
    Rails.logger.error "Error creating YouTube search video: #{e.message}"
    false
  end

  def search_videos(query:, filter:)
    params = {
      part: "snippet",
      type: "video",
      q: query,
      maxResults: NewsAggregatorConfig.youtube_search_max_results,
      order: NewsAggregatorConfig.youtube_search_order,
      relevanceLanguage: NewsAggregatorConfig.youtube_search_relevance_language,
      regionCode: NewsAggregatorConfig.youtube_search_region_code,
      publishedAfter: published_after_for(filter).utc.iso8601,
      key: self.class.api_key
    }

    duration = NewsAggregatorConfig.youtube_search_video_duration
    params[:videoDuration] = duration unless duration == "any"

    response = HTTParty.get(
      API_URL,
      query: params,
      timeout: NewsAggregatorConfig.request_timeout
    )

    unless response.success?
      body_preview = response.body.to_s.gsub(/\s+/, " ").strip[0, 200]
      raise NewsFetchers::BaseFetcher::FetchError,
            "HTTP #{response.code} for search.list: #{body_preview.presence || '(empty body)'}"
    end

    response.parsed_response
  end

  def published_after_for(filter)
    run = FetchRun.find_by(source_key: self.class.source_key_for(filter))
    return run.last_success_at if run&.last_success_at.present?

    NewsAggregatorConfig.youtube_search_published_after_days.days.ago
  end

  def too_soon?(filter)
    hours = NewsAggregatorConfig.youtube_search_min_interval_hours
    return false if hours <= 0

    run = FetchRun.find_by(source_key: self.class.source_key_for(filter))
    return false if run.blank? || run.finished_at.blank?

    run.finished_at > hours.hours.ago
  end

  def remaining_budget
    NewsAggregatorConfig.youtube_search_daily_call_budget - calls_today
  end

  def calls_today
    self.class.call_store.read(self.class.daily_calls_cache_key).to_i
  end

  def consume_call!
    key = self.class.daily_calls_cache_key
    self.class.call_store.write(key, calls_today + 1, expires_in: 36.hours)
  end

  def quota_exhausted_error?(error)
    message = error.message.to_s.downcase
    message.include?("quota") || message.include?("403")
  end

  def elapsed(started)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end
end
