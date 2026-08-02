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

  test "youtube source requires channel_id in config" do
    source = NewsSource.new(name: "Confreaks", source_type: "youtube", config: {})
    assert_not source.valid?
    assert_includes source.errors[:config], "must include channel_id"
  end

  test "build_fetcher returns correct fetcher class" do
    source = news_sources(:hacker_news)
    assert_instance_of NewsFetchers::HackerNewsFetcher, source.build_fetcher

    reddit = news_sources(:reddit_rust)
    fetcher = reddit.build_fetcher
    assert_instance_of NewsFetchers::RedditFetcher, fetcher
    assert_equal "rust", fetcher.instance_variable_get(:@subreddit)

    youtube = NewsSource.create!(
      name: "Confreaks",
      source_type: "youtube",
      active: true,
      config: { "channel_id" => "UCWnPjmqvljcafA0QXblOU1A", "channel_name" => "Confreaks" }
    )
    yt_fetcher = youtube.build_fetcher
    assert_instance_of NewsFetchers::YoutubeFetcher, yt_fetcher
    assert_equal "UCWnPjmqvljcafA0QXblOU1A", yt_fetcher.instance_variable_get(:@channel_id)
  end

  test "source_key matches fetcher keys" do
    assert_equal "hacker_news", news_sources(:hacker_news).source_key
    assert_equal "dev_to", news_sources(:dev_to).source_key
    assert_equal "reddit_rust", news_sources(:reddit_rust).source_key

    youtube = NewsSource.new(
      source_type: "youtube",
      config: { "channel_id" => "UCWnPjmqvljcafA0QXblOU1A" }
    )
    assert_equal "youtube_UCWnPjmqvljcafA0QXblOU1A", youtube.source_key
  end

  test "bootstrap_defaults creates default sources" do
    NewsSource.delete_all
    NewsSource.bootstrap_defaults!

    assert NewsSource.exists?(source_type: "hacker_news")
    assert NewsSource.exists?(source_type: "dev_to")
    assert_equal NewsAggregatorConfig.reddit_subreddits.length,
                 NewsSource.where(source_type: "reddit").count
    assert_equal NewsAggregatorConfig.youtube_channels.length,
                 NewsSource.where(source_type: "youtube").count
  end
end
