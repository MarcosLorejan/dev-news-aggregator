require "test_helper"

class SourcesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @reddit_source = news_sources(:reddit_rust)
  end

  test "should get index JSON" do
    get sources_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json["sources"].is_a?(Array)
    assert json["sources"].any? { |source| source["source_type"] == "hacker_news" }
  end

  test "index backfills default youtube channels when older DBs lack them" do
    NewsSource.where(source_type: "youtube").delete_all
    assert_equal 0, NewsSource.where(source_type: "youtube").count

    get sources_url, as: :json
    assert_response :success

    assert NewsSource.where(source_type: "youtube").exists?
    assert JSON.parse(response.body)["sources"].any? { |source| source["source_type"] == "youtube" }
  end

  test "index JSON includes last_fetch for sources with FetchRun" do
    FetchRun.record_outcome(
      source_key: "hacker_news",
      status: "success",
      articles_count: 12,
      duration_seconds: 1.5
    )

    FetchRun.record_outcome(
      source_key: "reddit_rust",
      status: "failure",
      articles_count: 0,
      error: StandardError.new("rate limited")
    )

    get sources_url, as: :json
    assert_response :success

    sources = JSON.parse(response.body)["sources"]
    hn = sources.find { |source| source["source_type"] == "hacker_news" }
    rust = sources.find { |source| source["subreddit"] == "rust" }
    never_fetched = sources.find { |source| source["source_type"] == "dev_to" }

    assert_equal "success", hn["last_fetch"]["status"]
    assert_equal 12, hn["last_fetch"]["articles_count"]
    assert_not_nil hn["last_fetch"]["finished_at"]
    assert_equal false, hn["last_fetch"]["empty"]
    assert_equal 1, hn["last_fetch"]["success_count"]
    assert_equal 100.0, hn["last_fetch"]["success_rate"]
    assert hn["last_fetch"].key?("last_article_at")

    assert_equal "failure", rust["last_fetch"]["status"]
    assert_equal "rate limited", rust["last_fetch"]["error_message"]
    assert_equal "StandardError", rust["last_fetch"]["error_class"]
    assert_equal 1, rust["last_fetch"]["failure_count"]

    assert_nil never_fetched["last_fetch"]
  end

  test "should toggle source active state" do
    patch source_url(@reddit_source), params: { active: false }, as: :json
    assert_response :success
    assert_not @reddit_source.reload.active

    patch source_url(@reddit_source), params: { active: true }, as: :json
    assert_response :success
    assert @reddit_source.reload.active
  end

  test "should not remove built-in source" do
    hn = news_sources(:hacker_news)
    delete source_url(hn), as: :json
    assert_response :unprocessable_entity
    assert NewsSource.exists?(hn.id)
  end

  test "should remove reddit source" do
    delete source_url(@reddit_source), as: :json
    assert_response :no_content
    assert_not NewsSource.exists?(@reddit_source.id)
  end

  test "should remove youtube source" do
    youtube = NewsSource.create!(
      name: "Confreaks",
      source_type: "youtube",
      config: { "channel_id" => "UCWnPjmqvljcafA0QXblOU1A", "channel_name" => "Confreaks" },
      active: true
    )

    delete source_url(youtube), as: :json
    assert_response :no_content
    assert_not NewsSource.exists?(youtube.id)
  end

  test "should reject invalid subreddit" do
    original = RedditSubredditValidator.method(:valid?)
    RedditSubredditValidator.define_singleton_method(:valid?) { |_subreddit| false }
    begin
      post sources_url, params: { source_type: "reddit", subreddit: "not-a-real-subreddit-xyz" }, as: :json
      assert_response :unprocessable_entity
      assert_equal "Subreddit not found or not accessible", JSON.parse(response.body)["error"]
    ensure
      RedditSubredditValidator.define_singleton_method(:valid?, original)
    end
  end

  test "should add valid subreddit" do
    original = RedditSubredditValidator.method(:valid?)
    RedditSubredditValidator.define_singleton_method(:valid?) { |_subreddit| true }
    begin
      assert_difference("NewsSource.count", 1) do
        post sources_url, params: { source_type: "reddit", subreddit: "golang" }, as: :json
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_equal "reddit", json["source_type"]
      assert_equal "golang", json["subreddit"]
    ensure
      RedditSubredditValidator.define_singleton_method(:valid?, original)
    end
  end

  test "should add valid youtube channel" do
    channel_id = "UCWnPjmqvljcafA0QXblOU1A"
    original = YoutubeChannelValidator.method(:resolve)
    YoutubeChannelValidator.define_singleton_method(:resolve) do |_input|
      YoutubeChannelValidator::Result.new(
        ok: true,
        channel_id: channel_id,
        channel_name: "Confreaks",
        error: nil
      )
    end
    begin
      assert_difference("NewsSource.count", 1) do
        post sources_url, params: { source_type: "youtube", channel: "@confreaks" }, as: :json
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_equal "youtube", json["source_type"]
      assert_equal channel_id, json["channel_id"]
      assert_equal "Confreaks", json["channel_name"]
    ensure
      YoutubeChannelValidator.define_singleton_method(:resolve) do |*args, **kwargs, &block|
        original.call(*args, **kwargs, &block)
      end
    end
  end

  test "should reject invalid youtube channel" do
    original = YoutubeChannelValidator.method(:resolve)
    YoutubeChannelValidator.define_singleton_method(:resolve) do |_input|
      YoutubeChannelValidator::Result.new(
        ok: false,
        channel_id: nil,
        channel_name: nil,
        error: "YouTube channel not found or feed unavailable"
      )
    end
    begin
      post sources_url, params: { source_type: "youtube", channel: "@nope" }, as: :json
      assert_response :unprocessable_entity
      assert_equal "YouTube channel not found or feed unavailable", JSON.parse(response.body)["error"]
    ensure
      YoutubeChannelValidator.define_singleton_method(:resolve) do |*args, **kwargs, &block|
        original.call(*args, **kwargs, &block)
      end
    end
  end
end
