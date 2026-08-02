class NewsFetchers::RedditFetcher < NewsFetchers::BaseFetcher
  USER_AGENT = "web:dev-news-aggregator:v1.0 (by /u/devnewsaggregator)"
  LINK_HREF_PATTERN = %r{<a\s+href="([^"]+)"\s*>\s*\[link\]\s*</a>}i
  OAUTH_TOKEN_URL = "https://www.reddit.com/api/v1/access_token"
  OAUTH_API_BASE = "https://oauth.reddit.com"

  base_uri "https://www.reddit.com"
  headers "User-Agent" => USER_AGENT

  class << self
    attr_writer :min_request_interval_seconds, :access_token, :access_token_expires_at, :rate_limit_backoff_seconds

    def min_request_interval_seconds
      @min_request_interval_seconds || NewsAggregatorConfig.reddit_min_request_interval_seconds
    end

    def rate_limit_backoff_seconds(attempt)
      if @rate_limit_backoff_seconds
        return @rate_limit_backoff_seconds.respond_to?(:call) ? @rate_limit_backoff_seconds.call(attempt) : @rate_limit_backoff_seconds
      end

      # 5s, 15s, 45s, ... capped
      [ 5 * (3**(attempt - 1)), 120 ].min
    end

    def reset_throttle!
      @last_request_at = nil
    end

    def reset_oauth_token!
      @access_token = nil
      @access_token_expires_at = nil
    end

    def throttle!
      @throttle_mutex ||= Mutex.new
      @throttle_mutex.synchronize do
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if @last_request_at
          wait = min_request_interval_seconds - (now - @last_request_at)
          sleep(wait) if wait.positive?
        end
        @last_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end

    def oauth_configured?
      ENV["REDDIT_CLIENT_ID"].present? && ENV["REDDIT_CLIENT_SECRET"].present?
    end

    def access_token
      @oauth_mutex ||= Mutex.new
      @oauth_mutex.synchronize do
        if @access_token.present? && @access_token_expires_at && Time.current < @access_token_expires_at
          return @access_token
        end

        fetch_access_token!
      end
    end

    def fetch_access_token!
      client_id = ENV.fetch("REDDIT_CLIENT_ID")
      client_secret = ENV.fetch("REDDIT_CLIENT_SECRET")

      response = HTTParty.post(
        OAUTH_TOKEN_URL,
        basic_auth: { username: client_id, password: client_secret },
        headers: {
          "User-Agent" => USER_AGENT,
          "Content-Type" => "application/x-www-form-urlencoded"
        },
        body: { grant_type: "client_credentials" },
        timeout: NewsAggregatorConfig.request_timeout
      )

      unless response.success?
        body_preview = response.body.to_s.gsub(/\s+/, " ").strip[0, 200]
        raise FetchError,
              "HTTP #{response.code} for #{OAUTH_TOKEN_URL}: #{body_preview.presence || '(empty body)'}"
      end

      payload = response.parsed_response
      token = payload.is_a?(Hash) ? payload["access_token"] : nil
      raise FetchError, "Reddit OAuth response missing access_token" if token.blank?

      expires_in = payload["expires_in"].to_i
      expires_in = 3600 if expires_in <= 0

      @access_token = token
      # Refresh slightly before expiry.
      @access_token_expires_at = Time.current + expires_in.seconds - 60.seconds
      @access_token
    end
  end

  def initialize(subreddit: "programming")
    super()
    @subreddit = subreddit
  end

  def source_key
    "reddit_#{@subreddit}"
  end

  def fetch_articles
    Rails.logger.info "Fetching articles from Reddit r/#{@subreddit}..."

    if self.class.oauth_configured?
      fetch_articles_via_oauth_json
    else
      fetch_articles_via_atom
    end

    Rails.logger.info "Fetched #{@articles.length} articles from Reddit r/#{@subreddit}"
    @articles
  end

  private

  def fetch_articles_via_atom
    Rails.logger.info "Reddit r/#{@subreddit}: using Atom feed (no scores without OAuth)"

    feed_body = fetch_with_rate_limit_retry { fetch_feed_body }
    entries = parse_atom_entries(feed_body)
    raise FetchError, "Reddit r/#{@subreddit} feed contained no entries" if entries.empty?

    entries.first(NewsAggregatorConfig.max_articles_per_source).each do |entry|
      create_article_from_atom_entry(entry)
    end
  end

  def fetch_articles_via_oauth_json
    Rails.logger.info "Reddit r/#{@subreddit}: using OAuth JSON listing (with scores)"

    payload = fetch_with_rate_limit_retry { fetch_oauth_listing }
    children = payload.dig("data", "children")
    raise FetchError, "Reddit r/#{@subreddit} JSON listing contained no posts" if children.blank?

    children.first(NewsAggregatorConfig.max_articles_per_source).each do |child|
      data = child.is_a?(Hash) ? child["data"] : nil
      next if data.blank?

      create_article_from_json_post(data)
    end
  end

  def fetch_feed_body
    response = self.class.get(
      "/r/#{@subreddit}/.rss",
      format: :plain,
      headers: { "User-Agent" => USER_AGENT }
    )

    body = response.to_s
    raise FetchError, "Empty Reddit r/#{@subreddit} Atom feed" if body.blank?

    body
  end

  def fetch_oauth_listing
    token = self.class.access_token
    limit = NewsAggregatorConfig.max_articles_per_source

    response = HTTParty.get(
      "#{OAUTH_API_BASE}/r/#{@subreddit}/hot",
      query: { limit: limit, raw_json: 1 },
      headers: {
        "User-Agent" => USER_AGENT,
        "Authorization" => "Bearer #{token}"
      },
      timeout: NewsAggregatorConfig.request_timeout
    )

    unless response.success?
      body_preview = response.body.to_s.gsub(/\s+/, " ").strip[0, 200]
      raise FetchError,
            "HTTP #{response.code} for #{response.request&.uri}: #{body_preview.presence || '(empty body)'}"
    end

    payload = response.parsed_response
    raise FetchError, "Invalid Reddit JSON listing for r/#{@subreddit}" unless payload.is_a?(Hash)

    payload
  end

  def fetch_with_rate_limit_retry
    attempt = 0
    max_attempts = NewsAggregatorConfig.reddit_rate_limit_max_retries + 1

    begin
      self.class.throttle!
      yield
    rescue FetchError => e
      raise unless rate_limited_error?(e)

      attempt += 1
      raise if attempt >= max_attempts

      wait = rate_limit_backoff_seconds(attempt)
      Rails.logger.warn(
        "Reddit r/#{@subreddit} rate limited (attempt #{attempt}/#{max_attempts - 1}); sleeping #{wait}s"
      )
      sleep(wait)
      retry
    end
  end

  def rate_limited_error?(error)
    error.message.match?(/HTTP 429\b/)
  end

  def rate_limit_backoff_seconds(attempt)
    self.class.rate_limit_backoff_seconds(attempt)
  end

  def parse_atom_entries(feed_body)
    document = Nokogiri::XML(feed_body)
    document.remove_namespaces!

    document.xpath("//entry").filter_map do |entry|
      title = entry.at_xpath("./title")&.text&.strip
      external_id = entry.at_xpath("./id")&.text&.strip
      permalink = entry.at_xpath("./link/@href")&.value&.strip
      published = entry.at_xpath("./published")&.text.presence ||
                  entry.at_xpath("./updated")&.text
      content_html = entry.at_xpath("./content")&.text.to_s

      next if title.blank? || external_id.blank? || permalink.blank?

      {
        title: title,
        external_id: external_id.delete_prefix("t3_"),
        permalink: permalink,
        published_at: published,
        content_html: content_html,
        article_url: extract_article_url(content_html, permalink)
      }
    end
  end

  def extract_article_url(content_html, permalink)
    unescaped = CGI.unescapeHTML(content_html.to_s)
    match = unescaped.match(LINK_HREF_PATTERN)
    link_url = match&.captures&.first

    if link_url.present? && !reddit_host?(link_url)
      link_url
    else
      permalink
    end
  end

  def reddit_host?(url)
    host = URI.parse(url).host&.downcase
    return false if host.blank?

    host == "reddit.com" || host.end_with?(".reddit.com")
  rescue URI::InvalidURIError
    false
  end

  def create_article_from_atom_entry(entry)
    published_at = Time.iso8601(entry[:published_at])
    description = Nokogiri::HTML.fragment(CGI.unescapeHTML(entry[:content_html])).text.squish
    source_type = "reddit_#{@subreddit}"

    article_attributes = {
      title: entry[:title],
      url: entry[:article_url],
      published_at: published_at,
      description: description,
      external_id: entry[:external_id],
      source_type: source_type
    }

    # Atom feeds do not include score/comments — only seed defaults on create.
    unless Article.exists?(external_id: entry[:external_id], source_type: source_type)
      article_attributes[:score] = 0
      article_attributes[:comment_count] = 0
    end

    article = create_or_update_article(article_attributes)
    @articles << article if article.persisted?
  rescue StandardError => e
    Rails.logger.error "Error creating Reddit article #{entry[:external_id]}: #{e.message}"
  end

  def create_article_from_json_post(data)
    external_id = data["id"].to_s
    title = data["title"].to_s.strip
    return if external_id.blank? || title.blank?

    permalink_path = data["permalink"].to_s
    permalink = permalink_path.start_with?("http") ? permalink_path : "https://www.reddit.com#{permalink_path}"

    url = data["url"].to_s
    article_url = url.present? && !reddit_host?(url) ? url : permalink

    published_at = Time.zone.at(data["created_utc"].to_f)
    description = data["selftext"].to_s.squish.presence || data["title"].to_s
    source_type = "reddit_#{@subreddit}"

    article = create_or_update_article(
      title: title,
      url: article_url,
      published_at: published_at,
      description: description,
      external_id: external_id,
      source_type: source_type,
      score: data["score"].to_i,
      comment_count: data["num_comments"].to_i
    )
    @articles << article if article.persisted?
  rescue StandardError => e
    Rails.logger.error "Error creating Reddit JSON article #{data['id']}: #{e.message}"
  end
end
