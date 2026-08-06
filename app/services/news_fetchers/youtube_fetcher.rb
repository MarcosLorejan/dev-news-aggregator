class NewsFetchers::YoutubeFetcher < NewsFetchers::BaseFetcher
  USER_AGENT = "dev-news-aggregator/1.0 (+https://github.com/MarcosLorejan/dev-news-aggregator)"
  FEED_HOST = "https://www.youtube.com"

  base_uri FEED_HOST
  headers "User-Agent" => USER_AGENT

  class << self
    attr_writer :min_request_interval_seconds, :rate_limit_backoff_seconds, :rate_limit_jitter_factor

    def min_request_interval_seconds
      @min_request_interval_seconds || NewsAggregatorConfig.youtube_min_request_interval_seconds
    end

    def rate_limit_jitter_factor
      @rate_limit_jitter_factor.nil? ? 0.25 : @rate_limit_jitter_factor
    end

    def rate_limit_backoff_seconds(attempt)
      if @rate_limit_backoff_seconds
        return @rate_limit_backoff_seconds.respond_to?(:call) ? @rate_limit_backoff_seconds.call(attempt) : @rate_limit_backoff_seconds
      end

      [ 5 * (3**(attempt - 1)), 120 ].min
    end

    def reset_throttle!
      @last_request_at = nil
    end

    def throttle!
      @throttle_mutex ||= Mutex.new
      @throttle_mutex.synchronize do
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if @last_request_at
          wait = min_request_interval_seconds - (now - @last_request_at)
          Kernel.sleep(wait) if wait.positive?
        end
        @last_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end

  def initialize(channel_id:, channel_name: nil)
    super()
    @channel_id = channel_id.to_s.strip
    @channel_name = channel_name.presence
    raise ArgumentError, "channel_id is required" if @channel_id.blank?
  end

  def source_key
    "youtube_#{@channel_id}"
  end

  def fetch_articles
    Rails.logger.info "Fetching YouTube channel #{@channel_id}..."

    feed_body = fetch_with_rate_limit_retry { fetch_feed_body }
    entries = parse_atom_entries(feed_body)
    raise FetchError, "YouTube channel #{@channel_id} feed contained no entries" if entries.empty?

    entries.first(NewsAggregatorConfig.max_articles_per_source).each do |entry|
      create_article_from_atom_entry(entry)
    end

    Rails.logger.info "Fetched #{@articles.length} videos from YouTube channel #{@channel_id}"
    @articles
  end

  private

  def fetch_feed_body
    response = self.class.get(
      "/feeds/videos.xml",
      query: { channel_id: @channel_id },
      format: :plain,
      headers: { "User-Agent" => USER_AGENT }
    )

    body = response.to_s
    raise FetchError, "Empty YouTube channel #{@channel_id} Atom feed" if body.blank?

    body
  end

  def fetch_with_rate_limit_retry
    attempt = 0
    max_attempts = NewsAggregatorConfig.youtube_rate_limit_max_retries + 1

    begin
      self.class.throttle!
      yield
    rescue FetchError => e
      raise unless rate_limited_error?(e)

      attempt += 1
      raise if attempt >= max_attempts

      wait = compute_rate_limit_wait(e, attempt)
      Rails.logger.warn(
        "YouTube channel #{@channel_id} rate limited (attempt #{attempt}/#{max_attempts - 1}); sleeping #{wait.round(2)}s"
      )
      Kernel.sleep(wait)
      retry
    end
  end

  def rate_limited_error?(error)
    error.is_a?(RateLimitedError) || error.message.match?(/HTTP 429\b/)
  end

  def compute_rate_limit_wait(error, attempt)
    header_wait = error.is_a?(RateLimitedError) ? error.retry_after_seconds : nil
    wait = header_wait.nil? ? self.class.rate_limit_backoff_seconds(attempt).to_f : header_wait.to_f
    max_wait = NewsAggregatorConfig.youtube_rate_limit_max_wait_seconds
    wait = [ wait, max_wait ].min
    return 0.0 if wait <= 0

    self.class.with_jitter(wait, factor: self.class.rate_limit_jitter_factor)
  end

  def parse_atom_entries(feed_body)
    document = Nokogiri::XML(feed_body)
    document.remove_namespaces!

    document.xpath("//entry").filter_map do |entry|
      video_id = entry.at_xpath("./videoId")&.text&.strip.presence ||
                 entry.at_xpath("./id")&.text&.to_s&.delete_prefix("yt:video:")&.strip
      title = entry.at_xpath("./title")&.text&.strip
      url = entry.at_xpath("./link/@href")&.value&.strip
      published = entry.at_xpath("./published")&.text.presence ||
                  entry.at_xpath("./updated")&.text
      description = entry.at_xpath("./group/description")&.text.to_s.strip
      thumbnail_url = entry.at_xpath("./group/thumbnail/@url")&.value&.strip
      author = entry.at_xpath("./author/name")&.text&.strip.presence || @channel_name
      views = entry.at_xpath("./group/community/statistics/@views")&.value

      next if video_id.blank? || title.blank? || url.blank?

      {
        video_id: video_id,
        title: title,
        url: url,
        published_at: published,
        description: description,
        thumbnail_url: thumbnail_url,
        author: author,
        views: views
      }
    end
  end

  def create_article_from_atom_entry(entry)
    if NewsAggregatorConfig.youtube_exclude_shorts? && short_entry?(entry)
      Rails.logger.info "Skipping YouTube Short #{entry[:video_id]} from #{@channel_id}"
      return
    end

    published_at = Time.iso8601(entry[:published_at])
    source_type = source_key

    article_attributes = {
      title: entry[:title],
      url: entry[:url],
      published_at: published_at,
      description: entry[:description].presence,
      external_id: entry[:video_id],
      source_type: source_type,
      content_type: "video",
      thumbnail_url: YoutubeThumbnail.preferred_url(entry[:thumbnail_url], video_id: entry[:video_id]),
      author: entry[:author],
      comment_count: 0
    }

    if entry[:views].present?
      article_attributes[:score] = entry[:views].to_i
    elsif !Article.exists?(external_id: entry[:video_id], source_type: source_type)
      article_attributes[:score] = 0
    end

    article = create_or_update_article(article_attributes)
    @articles << article if article.persisted?
  rescue StandardError => e
    Rails.logger.error "Error creating YouTube video #{entry[:video_id]}: #{e.message}"
  end

  def short_entry?(entry)
    url = entry[:url].to_s
    title = entry[:title].to_s
    url.match?(%r{/shorts/}i) || title.match?(/#\s*shorts\b/i)
  end
end
