class NewsFetchers::HackerNewsFetcher < NewsFetchers::BaseFetcher
  base_uri "https://hacker-news.firebaseio.com/v0"
  format :json

  def fetch_articles
    Rails.logger.info "Fetching articles from Hacker News..."

    # Get top stories
    top_story_ids = self.class.get("/topstories.json")
    return [] unless top_story_ids.is_a?(Array)

    story_ids = top_story_ids.first(NewsAggregatorConfig.max_articles_per_source)
    story_payloads = fetch_story_payloads_in_parallel(story_ids)

    story_payloads.each do |story_data|
      article = persist_story(story_data)
      @articles << article if article
    end

    Rails.logger.info "Fetched #{@articles.length} articles from Hacker News"
    @articles
  end

  private

  # Parallelize only HTTP item fetches so ActiveRecord stays on the caller thread
  # (NewsAggregatorService already holds a pool connection around fetch_articles).
  def fetch_story_payloads_in_parallel(story_ids)
    return [] if story_ids.empty?

    mutex = Mutex.new
    payloads = []
    concurrency = [ NewsAggregatorConfig.hn_item_concurrency, story_ids.size ].min

    story_ids.each_slice(concurrency) do |batch|
      threads = batch.map do |story_id|
        Thread.new do
          story_data = fetch_story_payload(story_id)
          mutex.synchronize { payloads << story_data } if story_data
        end
      end

      threads.each(&:join)
    end

    payloads
  end

  def fetch_story_payload(story_id)
    story_data = self.class.get("/item/#{story_id}.json")
    return unless story_data && story_data["type"] == "story"

    # Skip stories without URLs (Ask HN, etc.)
    return unless story_data["url"]

    story_data
  rescue StandardError => e
    Rails.logger.error "Error fetching HN story #{story_id}: #{e.message}"
    nil
  end

  def persist_story(story_data)
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
    article if article.persisted?
  rescue StandardError => e
    Rails.logger.error "Error persisting HN story #{story_data['id']}: #{e.message}"
    nil
  end
end
