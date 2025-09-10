class NewsFetchers::HackerNewsFetcher < NewsFetchers::BaseFetcher
  base_uri "https://hacker-news.firebaseio.com/v0"

  def fetch_articles
    Rails.logger.info "Fetching articles from Hacker News..."

    # Get top stories
    top_story_ids = self.class.get("/topstories.json")
    return [] unless top_story_ids.is_a?(Array)

    # Limit to first 30 stories to avoid rate limits
    top_story_ids.first(30).each do |story_id|
      fetch_story(story_id)
    end

    Rails.logger.info "Fetched #{@articles.length} articles from Hacker News"
    @articles
  end

  private

  def fetch_story(story_id)
    story_data = self.class.get("/item/#{story_id}.json")
    return unless story_data && story_data["type"] == "story"

    # Skip stories without URLs (Ask HN, etc.)
    return unless story_data["url"]

    article_attributes = {
      title: story_data["title"],
      url: story_data["url"],
      published_at: Time.at(story_data["time"]),
      description: story_data["text"] || "",
      external_id: story_data["id"].to_s,
      source_type: "hacker_news",
      score: story_data["score"] || 0,
      comment_count: story_data["descendants"] || 0
    }

    article = create_or_update_article(article_attributes)
    @articles << article if article.persisted?
  rescue StandardError => e
    Rails.logger.error "Error fetching HN story #{story_id}: #{e.message}"
  end
end
