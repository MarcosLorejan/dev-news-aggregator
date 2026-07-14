class NewsFetchers::RedditFetcher < NewsFetchers::BaseFetcher
  USER_AGENT = "web:dev-news-aggregator:v1.0 (by /u/devnewsaggregator)"
  LINK_HREF_PATTERN = %r{<a\s+href="([^"]+)"\s*>\s*\[link\]\s*</a>}i

  base_uri "https://www.reddit.com"
  headers "User-Agent" => USER_AGENT

  class << self
    attr_writer :min_request_interval_seconds

    def min_request_interval_seconds
      @min_request_interval_seconds || 1.2
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
          sleep(wait) if wait.positive?
        end
        @last_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
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
    Rails.logger.info "Fetching articles from Reddit r/#{@subreddit} (Atom feed)..."

    feed_body = fetch_feed_body
    entries = parse_atom_entries(feed_body)
    raise FetchError, "Reddit r/#{@subreddit} feed contained no entries" if entries.empty?

    entries.first(NewsAggregatorConfig.max_articles_per_source).each do |entry|
      create_article_from_entry(entry)
    end

    Rails.logger.info "Fetched #{@articles.length} articles from Reddit r/#{@subreddit}"
    @articles
  end

  private

  def fetch_feed_body
    self.class.throttle!

    response = self.class.get(
      "/r/#{@subreddit}/.rss",
      format: :plain,
      headers: { "User-Agent" => USER_AGENT }
    )

    body = response.to_s
    raise FetchError, "Empty Reddit r/#{@subreddit} Atom feed" if body.blank?

    body
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

  def create_article_from_entry(entry)
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
end
