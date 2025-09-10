require "test_helper"

class ReadArticlesWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @article = articles(:hacker_news_article)
    @dev_article = articles(:dev_to_article)
    @rust_article = articles(:reddit_rust_article)
  end

  test "should complete full read article workflow" do
    get articles_path
    assert_response :success

    post mark_article_as_read_path(@article)
    assert_redirected_to articles_path
    assert @article.reload.read?

    get read_articles_path
    assert_response :success
    assert_select "h1", "Already Read"

    delete unmark_article_as_read_path(@article)
    assert_redirected_to read_articles_path
    assert_not @article.reload.read?

    get articles_path
    assert_response :success
  end

  test "should handle multiple articles workflow" do
    post mark_article_as_read_path(@article)
    post mark_article_as_read_path(@dev_article)

    assert @article.reload.read?
    assert @dev_article.reload.read?

    get read_articles_path
    assert_response :success
  end

  test "should show read articles when explicitly requested" do
    post mark_article_as_read_path(@article)
    assert @article.reload.read?

    get articles_path
    assert_response :success

    get articles_path(show_read: true)
    assert_response :success
  end

  test "should handle AJAX requests for marking articles" do
    post mark_article_as_read_path(@article), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as read", json_response["message"]
    assert_equal true, json_response["read"]
    assert @article.reload.read?

    delete unmark_article_as_read_path(@article), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as unread", json_response["message"]
    assert_equal false, json_response["read"]
    assert_not @article.reload.read?
  end

  test "should navigate between sections correctly" do
    @article.mark_as_read!

    get articles_path
    assert_select "a[href='#{bookmarks_path}']", "Reading List"
    assert_select "a[href='#{read_articles_path}']", "Already Read"

    get read_articles_path
    assert_select "a[href='#{articles_path}']", "Back to All Articles"

    get bookmarks_path
    assert_select "a[href='#{articles_path}']", "Back to All Articles"
  end

  test "should maintain filtering state with read articles" do
    @article.mark_as_read!
    @dev_article.mark_as_read!

    get read_articles_path
    assert_response :success

    assert_select "[data-source='hacker_news']", minimum: 1
    assert_select "[data-source='dev_to']", minimum: 1
  end

  test "should handle error scenarios gracefully" do
    post mark_article_as_read_path(article_id: 99999)
    assert_redirected_to articles_path
    follow_redirect!
    assert_equal "Article not found", flash[:alert]

    delete unmark_article_as_read_path(article_id: 99999)
    assert_redirected_to read_articles_path
    follow_redirect!
    assert_equal "Article not found", flash[:alert]

    delete unmark_article_as_read_path(@article)
    assert_redirected_to read_articles_path
    follow_redirect!
    assert_equal "Article is not marked as read", flash[:alert]
  end
end
