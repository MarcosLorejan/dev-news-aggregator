require "test_helper"

class NewsSourceTest < ActiveSupport::TestCase
  test "validates presence and source type" do
    source = NewsSource.new
    assert_not source.valid?
    assert_includes source.errors[:name], "can't be blank"
    assert_includes source.errors[:source_type], "is not included in the list"
  end

  test "reddit source requires subreddit in config" do
    source = NewsSource.new(name: "test", source_type: "reddit", config: {})
    assert_not source.valid?
    assert_includes source.errors[:config], "must include subreddit"
  end

  test "build_fetcher returns correct fetcher class" do
    source = news_sources(:hacker_news)
    assert_instance_of NewsFetchers::HackerNewsFetcher, source.build_fetcher

    reddit = news_sources(:reddit_rust)
    fetcher = reddit.build_fetcher
    assert_instance_of NewsFetchers::RedditFetcher, fetcher
    assert_equal "rust", fetcher.instance_variable_get(:@subreddit)
  end

  test "bootstrap_defaults creates default sources" do
    NewsSource.delete_all
    NewsSource.bootstrap_defaults!

    assert NewsSource.exists?(source_type: "hacker_news")
    assert NewsSource.exists?(source_type: "dev_to")
    assert_equal NewsAggregatorConfig.reddit_subreddits.length,
                 NewsSource.where(source_type: "reddit").count
  end
end
