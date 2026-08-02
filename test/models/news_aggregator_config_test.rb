require "test_helper"

class NewsAggregatorConfigTest < ActiveSupport::TestCase
  test "loads fetching limits from news_aggregator.yml" do
    assert_equal 5, NewsAggregatorConfig.max_articles_per_source
    assert_equal 10, NewsAggregatorConfig.request_timeout
    assert_equal 3, NewsAggregatorConfig.max_retries
    assert_equal 3, NewsAggregatorConfig.hn_item_concurrency
  end

  test "loads retention days from news_aggregator.yml" do
    assert_equal 7, NewsAggregatorConfig.retention_days
  end

  test "loads reddit subreddits from news_aggregator.yml" do
    subreddits = NewsAggregatorConfig.reddit_subreddits

    assert_includes subreddits, "programming"
    assert_includes subreddits, "LocalLLaMA"
    assert_operator subreddits.length, :>=, 10
  end

  test "loads API base URLs from news_aggregator.yml" do
    assert_equal "https://hacker-news.firebaseio.com/v0", NewsAggregatorConfig.hacker_news_base_url
    assert_equal "https://dev.to/api", NewsAggregatorConfig.devto_base_url
    assert_equal "https://www.reddit.com/r", NewsAggregatorConfig.reddit_base_url
  end

  test "loads reddit throttle settings from news_aggregator.yml" do
    assert_equal 2.5, NewsAggregatorConfig.reddit_min_request_interval_seconds
    assert_equal 4, NewsAggregatorConfig.reddit_rate_limit_max_retries
  end
end
