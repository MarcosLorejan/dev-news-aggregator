require "test_helper"

class Api::V1::ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:hacker_news_article)
  end

  test "index returns paginated articles json" do
    get api_v1_articles_url, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert body["articles"].is_a?(Array)
    assert body["pagination"]["total_count"].positive?
  end

  test "index supports q search" do
    get api_v1_articles_url(q: "Rust"), as: :json
    assert_response :success

    titles = JSON.parse(response.body)["articles"].map { |row| row["title"] }
    assert titles.any? { |title| title.include?("Rust") }
  end

  test "show returns article" do
    get api_v1_article_url(@article), as: :json
    assert_response :success
    assert_equal @article.id, JSON.parse(response.body)["id"]
  end

  test "bookmark and unbookmark via api" do
    post bookmark_api_v1_article_url(@article), as: :json
    assert_response :success
    assert JSON.parse(response.body)["bookmarked"]
    assert @article.reload.bookmarked?

    delete unbookmark_api_v1_article_url(@article), as: :json
    assert_response :success
    assert_not JSON.parse(response.body)["bookmarked"]
  end

  test "dismiss and undismiss via api" do
    post dismiss_api_v1_article_url(@article), as: :json
    assert_response :success
    assert_equal "dismissed", JSON.parse(response.body)["status"]

    delete undismiss_api_v1_article_url(@article), as: :json
    assert_response :success
    assert_equal "restored", JSON.parse(response.body)["status"]
  end
end
