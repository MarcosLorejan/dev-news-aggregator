class RedditSubredditValidator
  USER_AGENT = "DevNewsAggregator/1.0"

  def self.valid?(subreddit)
    normalized = normalize(subreddit)
    return false if normalized.blank?

    cache_key = "reddit_subreddit_valid:#{normalized}"
    cached = Rails.cache.read(cache_key)
    return cached unless cached.nil?

    response = HTTParty.get(
      "https://www.reddit.com/r/#{normalized}/about.json",
      headers: { "User-Agent" => USER_AGENT },
      timeout: 5
    )

    valid = response.code == 200 &&
            response.parsed_response.is_a?(Hash) &&
            response.dig("data", "subreddit_type") != "banned"

    Rails.cache.write(cache_key, valid, expires_in: 1.hour)
    valid
  rescue StandardError
    false
  end

  def self.normalize(subreddit)
    subreddit.to_s.strip.downcase.delete_prefix("r/").delete_prefix("/r/")
  end
end
