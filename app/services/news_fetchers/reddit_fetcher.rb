class NewsFetchers::RedditFetcher < NewsFetchers::BaseFetcher
  base_uri "https://www.reddit.com"
  headers "User-Agent" => "DevNewsAggregator/1.0"

  def initialize(subreddit: "programming")
    super()
    @subreddit = subreddit
  end

  def fetch_articles
    Rails.logger.info "Fetching articles from Reddit r/#{@subreddit}..."

    # Get hot posts from subreddit
    response = self.class.get("/r/#{@subreddit}.json", query: { limit: 25 })
    return [] unless response && response["data"]

    posts_data = response.dig("data", "children")
    return [] unless posts_data.is_a?(Array)

    posts_data.each do |post|
      create_article_from_post(post["data"])
    end

    Rails.logger.info "Fetched #{@articles.length} articles from Reddit r/#{@subreddit}"
    @articles
  end

  private

  def create_article_from_post(post_data)
    # Skip self posts without URLs
    return if post_data["is_self"] && post_data["url_overridden_by_dest"].nil?

    # Use external URL if available, otherwise Reddit permalink
    article_url = post_data["url_overridden_by_dest"] ||
                  "https://reddit.com#{post_data['permalink']}"

    article_attributes = {
      title: post_data["title"],
      url: article_url,
      published_at: Time.at(post_data["created_utc"]),
      description: post_data["selftext"] || "",
      external_id: post_data["id"],
      source_type: "reddit_#{@subreddit}",
      score: post_data["score"] || 0,
      comment_count: post_data["num_comments"] || 0
    }

    article = create_or_update_article(article_attributes)
    @articles << article if article.persisted?
  rescue StandardError => e
    Rails.logger.error "Error creating Reddit article #{post_data['id']}: #{e.message}"
  end
end
