require "test_helper"

class ReadArticlesWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @article = articles(:hacker_news_article)
    @dev_article = articles(:dev_to_article)
    @rust_article = articles(:reddit_rust_article)
  end

  test "should complete full read article workflow" do
    # Start on articles index - should show all unread articles
    get articles_path
    assert_response :success
    assert_select "h3", text: @article.title, count: 1
    assert_select "h3", text: @dev_article.title, count: 1
    assert_select ".already-read-button", count: 3 # Should have read buttons

    # Mark an article as read
    post mark_read_article_path(@article)
    assert_redirected_to articles_path
    follow_redirect!

    # Should no longer show the read article on main index
    assert_select "h3", text: @article.title, count: 0
    assert_select "h3", text: @dev_article.title, count: 1

    # Navigate to Already Read section
    get read_articles_path
    assert_response :success
    assert_select "h1", "Already Read"
    assert_select "h3", text: @article.title, count: 1
    assert_select ".mark-unread-button", count: 1

    # Mark article as unread from Already Read page
    delete mark_unread_article_path(@article)
    assert_redirected_to read_articles_path
    follow_redirect!

    # Should show empty state
    assert_select ".empty-state"
    assert_select "p", text: /You haven't marked any articles as read yet/

    # Go back to main articles and verify article is back
    get articles_path
    assert_response :success
    assert_select "h3", text: @article.title, count: 1
  end

  test "should handle multiple articles workflow" do
    # Mark multiple articles as read
    post mark_read_article_path(@article)
    post mark_read_article_path(@dev_article)

    # Check main index excludes both
    get articles_path
    assert_select "h3", text: @article.title, count: 0
    assert_select "h3", text: @dev_article.title, count: 0
    assert_select "h3", text: @rust_article.title, count: 1

    # Check Already Read page shows both
    get read_articles_path
    assert_select "h3", text: @article.title, count: 1
    assert_select "h3", text: @dev_article.title, count: 1
    assert_select ".mark-unread-button", count: 2

    # Check articles grouped by source
    assert_select ".source-section", count: 2 # hacker_news and dev_to
  end

  test "should show read articles when explicitly requested" do
    # Mark an article as read
    post mark_read_article_path(@article)

    # Normal index should not show read article
    get articles_path
    assert_select "h3", text: @article.title, count: 0

    # Index with show_read=true should show read article
    get articles_path(show_read: true)
    assert_select "h3", text: @article.title, count: 1
    assert_select "h3", text: @dev_article.title, count: 1
  end

  test "should handle AJAX requests for marking articles" do
    # Mark as read via AJAX
    post mark_read_article_path(@article), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as read", json_response["message"]
    assert_equal true, json_response["read"]
    assert @article.reload.read?

    # Mark as unread via AJAX
    delete mark_unread_article_path(@article), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Article marked as unread", json_response["message"]
    assert_equal false, json_response["read"]
    assert_not @article.reload.read?
  end

  test "should navigate between sections correctly" do
    # Mark an article as read
    @article.mark_read!

    # Main articles page should have links to both Reading List and Already Read
    get articles_path
    assert_select "a[href='#{bookmarks_path}']", "Reading List"
    assert_select "a[href='#{read_articles_path}']", "Already Read"

    # Already Read page should have back link
    get read_articles_path
    assert_select "a[href='#{articles_path}']", "Back to Articles"

    # Reading List page should have back link
    get bookmarks_path
    assert_select "a[href='#{articles_path}']", "Back to Articles"
  end

  test "should maintain filtering state with read articles" do
    # Mark articles from different sources as read
    @article.mark_read! # hacker_news
    @dev_article.mark_read! # dev_to

    get read_articles_path
    assert_response :success

    # Should be able to filter by source on Already Read page
    # This tests that the filtering JavaScript would work correctly
    assert_select "[data-source='hacker_news']", minimum: 1
    assert_select "[data-source='dev_to']", minimum: 1
  end

  test "should handle error scenarios gracefully" do
    # Try to mark non-existent article as read
    post mark_read_article_path(id: 99999)
    assert_redirected_to articles_path
    follow_redirect!
    assert_equal "Article not found", flash[:alert]

    # Try to unmark non-existent article
    delete mark_unread_article_path(id: 99999)
    assert_redirected_to read_articles_path
    follow_redirect!
    assert_equal "Article not found", flash[:alert]

    # Try to unmark article that's not read
    delete mark_unread_article_path(@article)
    assert_redirected_to read_articles_path
    follow_redirect!
    assert_equal "Article is not marked as read", flash[:alert]
  end
end
