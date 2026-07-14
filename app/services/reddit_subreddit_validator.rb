class RedditSubredditValidator
  USER_AGENT = NewsFetchers::RedditFetcher::USER_AGENT

  def self.valid?(subreddit)
    normalized = normalize(subreddit)
    return false if normalized.blank?

    cache_key = "reddit_subreddit_valid:#{normalized}"
    cached = Rails.cache.read(cache_key)
    return cached unless cached.nil?

    NewsFetchers::RedditFetcher.throttle!

    response = HTTParty.get(
      "https://www.reddit.com/r/#{normalized}/.rss",
      headers: { "User-Agent" => USER_AGENT },
      timeout: 5
    )

    valid = response.code == 200 && response.body.to_s.include?("<feed")

    Rails.cache.write(cache_key, valid, expires_in: 1.hour)
    valid
  rescue StandardError
    false
  end

  def self.normalize(subreddit)
    subreddit.to_s.strip.downcase.delete_prefix("r/").delete_prefix("/r/")
  end
end
