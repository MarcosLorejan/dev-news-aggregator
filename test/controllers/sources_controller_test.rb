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

  test "should not remove non-reddit source" do
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

  test "should reject invalid subreddit" do
    original = RedditSubredditValidator.method(:valid?)
    RedditSubredditValidator.define_singleton_method(:valid?) { |_subreddit| false }
    begin
      post sources_url, params: { subreddit: "not-a-real-subreddit-xyz" }, as: :json
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
        post sources_url, params: { subreddit: "golang" }, as: :json
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_equal "reddit", json["source_type"]
      assert_equal "golang", json["subreddit"]
    ensure
      RedditSubredditValidator.define_singleton_method(:valid?, original)
    end
  end
end
