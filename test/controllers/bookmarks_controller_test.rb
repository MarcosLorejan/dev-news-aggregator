require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @bookmarked_article = articles(:reddit_rust_article)
    @unbookmarked_article = articles(:hacker_news_article)
  end

  test "should get index" do
    get bookmarks_url
    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "index JSON should include bookmarked articles" do
    get bookmarks_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["articles"].is_a?(Array)
    assert json_response["articles"].any? { |article| article["id"] == @bookmarked_article.id }
    assert json_response["articles"].all? { |article| article.key?("bookmarked_at") }
  end

  test "should show empty state when no bookmarks exist" do
    Bookmark.destroy_all

    get bookmarks_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 0, json_response["pagination"]["total_count"]
    assert_empty json_response["articles"]
  end

  test "index JSON should group articles by source" do
    get bookmarks_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["articles_by_source"].is_a?(Hash)
    assert json_response["articles_by_source"].key?(@bookmarked_article.source_type)
  end

  test "index should return JSON with bookmarked articles" do
    get bookmarks_url, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert json_response.key?("articles")
    assert json_response.key?("pagination")
    assert json_response.key?("articles_by_source")

    assert json_response["articles"].is_a?(Array)
    assert json_response["pagination"]["current_page"] == 1
  end

  test "index JSON should support pagination" do
    get bookmarks_url(page: 1, per_page: 5), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal 1, json_response["pagination"]["current_page"]
    assert_equal 5, json_response["pagination"]["per_page"]
  end
end
