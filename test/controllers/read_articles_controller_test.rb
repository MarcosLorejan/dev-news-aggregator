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
    assert_select ".empty-state"
    assert_select "p", text: /You haven't marked any articles as read yet/
  end

  test "should group read articles by source" do
    dev_article = articles(:dev_to_article)
    ReadArticle.create!(article: dev_article)
    
    get read_articles_path
    assert_response :success
    assert_select ".source-section", count: 2
  end

  test "should display read timestamps" do
    get read_articles_path
    assert_select ".text-purple-300", text: /Read/
  end

  test "should show unmark read buttons" do
    get read_articles_path
    assert_select "form[action='#{mark_unread_article_path(@article)}']"
    assert_select "button", text: "Mark as Unread"
  end

  test "should show back to articles link" do
    get read_articles_path
    assert_select "a[href='#{articles_path}']", text: "Back to Articles"
  end

  test "should mark article as read" do
    unread_article = articles(:dev_to_article)
    assert_difference "ReadArticle.count", 1 do
      post mark_read_article_path(unread_article)
    end
    assert_redirected_to articles_path
    assert unread_article.reload.read?
  end

  test "should mark article as read and respond to JSON" do
    unread_article = articles(:dev_to_article)
    assert_difference "ReadArticle.count", 1 do
      post mark_read_article_path(unread_article), as: :json
    end
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as read", json_response["message"]
    assert_equal true, json_response["read"]
  end

  test "should handle mark read of non-existent article" do
    assert_no_difference "ReadArticle.count" do
      post mark_read_article_path(id: 99999)
    end
    assert_redirected_to articles_path
    assert_equal "Article not found", flash[:alert]
  end

  test "should mark article as unread" do
    assert_difference "ReadArticle.count", -1 do
      delete mark_unread_article_path(@article)
    end
    assert_redirected_to read_articles_path
    assert_not @article.reload.read?
  end

  test "should mark article as unread and respond to JSON" do
    assert_difference "ReadArticle.count", -1 do
      delete mark_unread_article_path(@article), as: :json
    end
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as unread", json_response["message"]
    assert_equal false, json_response["read"]
  end

  test "should handle unmark read of non-existent article" do
    assert_no_difference "ReadArticle.count" do
      delete mark_unread_article_path(id: 99999)
    end
    assert_redirected_to read_articles_path
    assert_equal "Article not found", flash[:alert]
  end

  test "should handle unmark read of article that is not read" do
    unread_article = articles(:dev_to_article)
    assert_no_difference "ReadArticle.count" do
      delete mark_unread_article_path(unread_article)
    end
    assert_redirected_to read_articles_path
    assert_equal "Article is not marked as read", flash[:alert]
  end
end
