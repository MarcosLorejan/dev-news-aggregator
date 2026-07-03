require "test_helper"

class DismissedArticlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @dismissed_article = articles(:hacker_news_article)
    @dismissed_article.dismiss!
    @dismissed_article.dismissed_article.update!(permanent: true)

    @recent_dismissed = articles(:dev_to_article)
    @recent_dismissed.dismiss!
  end

  test "should get index" do
    get dismissed_articles_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "index JSON should include dismissed articles" do
    get dismissed_articles_path, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["articles"].is_a?(Array)
    assert json_response["articles"].any? { |article| article["id"] == @dismissed_article.id }
    assert json_response["articles"].all? { |article| article.key?("dismissed_at") }
  end

  test "should get recently_dismissed" do
    get recently_dismissed_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "recently dismissed JSON should include recent articles" do
    get recently_dismissed_path, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["articles"].is_a?(Array)
    assert json_response["articles"].any? { |article| article["id"] == @recent_dismissed.id }
  end

  test "should not show old dismissed articles in recently dismissed JSON" do
    old_dismissed = articles(:reddit_rust_article)
    old_dismissed.dismiss!
    old_dismissed.dismissed_article.update!(dismissed_at: 2.days.ago)

    get recently_dismissed_path, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    ids = json_response["articles"].map { |article| article["id"] }
    assert_not_includes ids, old_dismissed.id
  end

  test "index should return JSON with dismissed articles" do
    get dismissed_articles_path, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert json_response.key?("articles")
    assert json_response.key?("pagination")

    assert json_response["articles"].is_a?(Array)
    assert json_response["pagination"]["current_page"] == 1
  end

  test "index JSON should support pagination" do
    get dismissed_articles_path(page: 1, per_page: 20), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal 1, json_response["pagination"]["current_page"]
    assert_equal 20, json_response["pagination"]["per_page"]
  end

  test "recently_dismissed should return JSON" do
    get recently_dismissed_path, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert json_response.key?("articles")
    assert json_response["articles"].is_a?(Array)
  end
end
