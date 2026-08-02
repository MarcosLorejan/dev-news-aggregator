# Fills in duration/stats for YouTube videos using videos.list (1 quota unit per
# call, up to 50 IDs). No-ops when YOUTUBE_API_KEY is unset so Atom-only works.
class YoutubeVideoEnricher
  include HTTParty

  API_URL = "https://www.googleapis.com/youtube/v3/videos"
  DEFAULT_BATCH_SIZE = 50

  class << self
    def enrich!(limit: nil)
      new.enrich!(limit: limit)
    end

    def api_key
      ENV["YOUTUBE_API_KEY"].presence
    end

    def enabled?
      NewsAggregatorConfig.youtube_enrich_with_api? && api_key.present?
    end
  end

  def enrich!(limit: nil)
    unless self.class.enabled?
      Rails.logger.info "YouTube video enrichment skipped (no API key or enrich_with_api disabled)"
      return { enriched: 0, skipped: true }
    end

    scope = Article.videos.where(duration_seconds: nil).order(published_at: :desc)
    max = limit || NewsAggregatorConfig.youtube_enrich_max_per_run
    candidates = scope.limit(max).to_a
    return { enriched: 0, skipped: false } if candidates.empty?

    enriched = 0
    candidates.each_slice(NewsAggregatorConfig.youtube_enrich_batch_size) do |batch|
      enriched += enrich_batch(batch)
    end

    { enriched: enriched, skipped: false }
  rescue StandardError => e
    Rails.error.report(e, handled: true, context: { service: "YoutubeVideoEnricher" })
    Rails.logger.error "YouTube video enrichment failed: #{e.class}: #{e.message}"
    { enriched: 0, skipped: false, error: e.message }
  end

  private

  def enrich_batch(articles)
    ids = articles.map(&:external_id)
    payload = fetch_videos(ids)
    items = payload.is_a?(Hash) ? Array(payload["items"]) : []
    by_id = items.index_by { |item| item["id"].to_s }

    updated = 0
    articles.each do |article|
      item = by_id[article.external_id.to_s]
      next unless item

      attributes = attributes_from_item(item)
      next if attributes.empty?

      article.update!(attributes)
      updated += 1
      discard_if_too_long!(article)
    rescue StandardError => e
      Rails.logger.error "Failed to enrich YouTube video #{article.external_id}: #{e.message}"
    end
    updated
  end

  def discard_if_too_long!(article)
    max = NewsAggregatorConfig.youtube_max_duration_seconds.to_i
    return if max <= 0
    return if article.duration_seconds.blank? || article.duration_seconds <= max
    return if article.bookmarked? || article.read?

    Rails.logger.info(
      "Discarding YouTube video #{article.external_id} (#{article.duration_seconds}s > #{max}s cap)"
    )
    article.destroy!
  end

  def fetch_videos(ids)
    response = HTTParty.get(
      API_URL,
      query: {
        part: "contentDetails,statistics",
        id: ids.join(","),
        key: self.class.api_key
      },
      timeout: NewsAggregatorConfig.request_timeout
    )

    unless response.success?
      body_preview = response.body.to_s.gsub(/\s+/, " ").strip[0, 200]
      raise NewsFetchers::BaseFetcher::FetchError,
            "HTTP #{response.code} for videos.list: #{body_preview.presence || '(empty body)'}"
    end

    response.parsed_response
  end

  def attributes_from_item(item)
    attributes = {}

    duration = item.dig("contentDetails", "duration")
    seconds = parse_duration_seconds(duration)
    attributes[:duration_seconds] = seconds if seconds

    stats = item["statistics"]
    if stats.is_a?(Hash)
      attributes[:score] = stats["viewCount"].to_i if stats.key?("viewCount")
      attributes[:comment_count] = stats["commentCount"].to_i if stats.key?("commentCount")
    end

    attributes
  end

  # PT1H2M3S / PT7M32S / PT45S → integer seconds. Returns nil when unparseable.
  def parse_duration_seconds(value)
    return nil if value.blank?

    ActiveSupport::Duration.parse(value).to_i
  rescue ArgumentError, TypeError
    nil
  end
end
