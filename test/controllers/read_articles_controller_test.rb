require "test_helper"

class ReadArticlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @article = articles(:hacker_news_article)
    @read_article = ReadArticle.create!(article: @article)
  end

  test "should get index" do
    get read_articles_path
    assert_response :success
    assert_select "h1", "Already Read"
  end

  test "should display read articles" do
    get read_articles_path
    assert_select ".article-card", count: 1
    assert_select "h3", @article.title
  end

  test "should show empty state when no read articles exist" do
    ReadArticle.destroy_all
    get read_articles_path
    assert_response :success
    assert_select "h2", text: "No read articles yet"
    assert_select "p", text: /Articles you mark as read will appear here/
  end

  test "should group read articles by source" do
    dev_article = articles(:dev_to_article)
    ReadArticle.create!(article: dev_article)
    
    get read_articles_path
    assert_response :success
    assert_select "button[data-source]", minimum: 2 # Should have filter buttons for different sources
  end

  test "should display read timestamps" do
    get read_articles_path
    assert_select "span", text: /Read/
  end

  test "should show back to articles link" do
    get read_articles_path
    assert_select "a[href='#{articles_path}']", text: "Back to All Articles"
  end

  test "should show unmark read buttons" do
    get read_articles_path
    assert_select "form[action='#{unmark_article_as_read_path(@article)}']"
    assert_select "button[type='submit']", count: 1 # Should have unmark button
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
end
