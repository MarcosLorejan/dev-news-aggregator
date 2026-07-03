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
