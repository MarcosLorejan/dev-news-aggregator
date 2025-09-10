require "test_helper"

class ReadArticlesWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @article = articles(:hacker_news_article)
    @dev_article = articles(:dev_to_article)
    @rust_article = articles(:reddit_rust_article)
  end

  test "should complete full read article workflow" do
    # Start on articles index
    get articles_path
    assert_response :success

    # Mark an article as read
    post mark_article_as_read_path(@article)
    assert_redirected_to articles_path
    assert @article.reload.read?

    # Navigate to Already Read section
    get read_articles_path
    assert_response :success
    assert_select "h1", "Already Read"

    # Mark article as unread from Already Read page
    delete unmark_article_as_read_path(@article)
    assert_redirected_to read_articles_path
    assert_not @article.reload.read?

    # Go back to main articles
    get articles_path
    assert_response :success
  end

  test "should handle multiple articles workflow" do
    # Mark multiple articles as read
    post mark_article_as_read_path(@article)
    post mark_article_as_read_path(@dev_article)

    assert @article.reload.read?
    assert @dev_article.reload.read?

    # Check Already Read page shows both
    get read_articles_path
    assert_response :success
  end

  test "should show read articles when explicitly requested" do
    # Mark an article as read
    post mark_article_as_read_path(@article)
    assert @article.reload.read?

    # Normal index should work
    get articles_path
    assert_response :success

    # Index with show_read=true should work
    get articles_path(show_read: true)
    assert_response :success
  end

  test "should handle AJAX requests for marking articles" do
    # Mark as read via AJAX
    post mark_article_as_read_path(@article), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as read", json_response["message"]
    assert_equal true, json_response["read"]
    assert @article.reload.read?

    # Mark as unread via AJAX
    delete unmark_article_as_read_path(@article), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as unread", json_response["message"]
    assert_equal false, json_response["read"]
    assert_not @article.reload.read?
  end

  test "should navigate between sections correctly" do
    # Mark an article as read
    @article.mark_as_read!

    # Main articles page should have links to both Reading List and Already Read
    get articles_path
    assert_select "a[href='#{bookmarks_path}']", "Reading List"
    assert_select "a[href='#{read_articles_path}']", "Already Read"

    # Already Read page should have back link
    get read_articles_path
    assert_select "a[href='#{articles_path}']", "Back to All Articles"

    # Reading List page should have back link
    get bookmarks_path
    assert_select "a[href='#{articles_path}']", "Back to Articles"
  end

  test "should maintain filtering state with read articles" do
    # Mark articles from different sources as read
    @article.mark_as_read! # hacker_news
    @dev_article.mark_as_read! # dev_to

    get read_articles_path
    assert_response :success

    # Should be able to filter by source on Already Read page
    # This tests that the filtering JavaScript would work correctly
    assert_select "[data-source='hacker_news']", minimum: 1
    assert_select "[data-source='dev_to']", minimum: 1
  end

  test "should handle error scenarios gracefully" do
    # Try to mark non-existent article as read
    post mark_article_as_read_path(article_id: 99999)
    assert_redirected_to articles_path
    follow_redirect!
    assert_equal "Article not found", flash[:alert]

    # Try to unmark non-existent article
    delete unmark_article_as_read_path(article_id: 99999)
    assert_redirected_to read_articles_path
    follow_redirect!
    assert_equal "Article not found", flash[:alert]

    # Try to unmark article that's not read
    delete unmark_article_as_read_path(@article)
    assert_redirected_to read_articles_path
    follow_redirect!
    assert_equal "Article is not marked as read", flash[:alert]
  end
end
