require "test_helper"

class ReadArticlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @article = articles(:hacker_news_article)
    @read_article = ReadArticle.create!(article: @article)
  end

  test "should get index" do
    get read_articles_path
    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "index JSON should include read articles" do
    get read_articles_path, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["articles"].is_a?(Array)
    assert json_response["articles"].any? { |article| article["id"] == @article.id }
    assert json_response["articles"].all? { |article| article.key?("read_at") }
  end

  test "should show empty state when no read articles exist" do
    ReadArticle.destroy_all

    get read_articles_path, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 0, json_response["pagination"]["total_count"]
    assert_empty json_response["articles"]
  end

  test "index JSON should group articles by source" do
    dev_article = articles(:dev_to_article)
    ReadArticle.create!(article: dev_article)

    get read_articles_path, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["articles_by_source"].is_a?(Hash)
    assert json_response["articles_by_source"].keys.length >= 2
  end

  test "should mark article as read" do
    unread_article = articles(:dev_to_article)
    assert_difference "ReadArticle.count", 1 do
      post mark_article_as_read_path(unread_article)
    end
    assert_redirected_to articles_path
    assert unread_article.reload.read?
  end

  test "should mark article as read and respond to JSON" do
    unread_article = articles(:dev_to_article)
    assert_difference "ReadArticle.count", 1 do
      post mark_article_as_read_path(unread_article), as: :json
    end
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as read", json_response["message"]
    assert_equal true, json_response["read"]
  end

  test "double mark as read JSON is idempotent" do
    unread_article = articles(:dev_to_article)

    post mark_article_as_read_path(unread_article), as: :json
    assert_response :ok

    assert_no_difference "ReadArticle.count" do
      post mark_article_as_read_path(unread_article), as: :json
    end

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal true, json_response["read"]
    assert_equal 1, ReadArticle.where(article_id: unread_article.id).count
  end

  test "should handle mark read of non-existent article" do
    assert_no_difference "ReadArticle.count" do
      post mark_article_as_read_path(article_id: 99999)
    end
    assert_redirected_to articles_path
    assert_equal "Article not found", flash[:alert]
  end

  test "should mark article as unread" do
    assert_difference "ReadArticle.count", -1 do
      delete unmark_article_as_read_path(@article)
    end
    assert_redirected_to read_articles_path
    assert_not @article.reload.read?
  end

  test "should mark article as unread and respond to JSON" do
    assert_difference "ReadArticle.count", -1 do
      delete unmark_article_as_read_path(@article), as: :json
    end
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as unread", json_response["message"]
    assert_equal false, json_response["read"]
  end

  test "should handle unmark read of non-existent article" do
    assert_no_difference "ReadArticle.count" do
      delete unmark_article_as_read_path(article_id: 99999)
    end
    assert_redirected_to read_articles_path
    assert_equal "Article not found", flash[:alert]
  end

  test "should handle unmark read of article that is not read" do
    unread_article = articles(:dev_to_article)
    assert_no_difference "ReadArticle.count" do
      delete unmark_article_as_read_path(unread_article)
    end
    assert_redirected_to read_articles_path
    assert_equal "Article is not marked as read", flash[:alert]
  end

  test "index should return JSON with read articles" do
    get read_articles_path, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert json_response.key?("articles")
    assert json_response.key?("pagination")
    assert json_response.key?("articles_by_source")

    assert json_response["articles"].is_a?(Array)
    assert json_response["pagination"]["current_page"] == 1
  end

  test "index JSON should support pagination" do
    get read_articles_path(page: 1, per_page: 10), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal 1, json_response["pagination"]["current_page"]
    assert_equal 10, json_response["pagination"]["per_page"]
  end
end
