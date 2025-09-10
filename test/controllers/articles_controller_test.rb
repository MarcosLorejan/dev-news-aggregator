require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @article = articles(:hacker_news_article)
    @dev_to_article = articles(:dev_to_article)
    @rust_article = articles(:reddit_rust_article)
  end

  test "should get index" do
    get articles_url
    assert_response :success

    # Check that articles are displayed
    assert_select "article.article-card", minimum: 1
    assert_select "h1", "Developer News Aggregator"
  end

  test "index should show articles grouped by source" do
    get articles_url
    assert_response :success

    # Should have filter buttons for different sources
    assert_select "button[data-filter-type='all']", text: /All Articles/
    assert_select "button[data-filter-type='category']", minimum: 1
  end

  test "index should show reading list link" do
    get articles_url
    assert_response :success

    assert_select "a[href='#{bookmarks_path}']", "Reading List"
  end

  test "index should show already read link" do
    get articles_url
    assert_response :success

    assert_select "a[href='#{read_articles_path}']", "Already Read"
  end

  test "index should exclude read articles by default" do
    # Mark one article as read
    @article.mark_as_read!
    
    get articles_url
    assert_response :success
    
    # Should not show the read article
    assert_select "h3", text: @article.title, count: 0
    # Should still show unread articles
    assert_select "h3", text: @dev_to_article.title, count: 1
  end

  test "index should include read articles when show_read param is true" do
    # Mark one article as read
    @article.mark_as_read!
    
    get articles_url(show_read: true)
    assert_response :success
    
    # Should show the read article when explicitly requested
    assert_select "h3", text: @article.title, count: 1
    # Should also show unread articles
    assert_select "h3", text: @dev_to_article.title, count: 1
  end

  test "should get show" do
    get article_url(@article)
    assert_response :success

    assert_select "h1", @article.title
    assert_select "a[href='#{@article.url}'][target='_blank']", "Visit Source"
  end

  test "show should display bookmark button when not bookmarked" do
    get article_path(@article)

    assert_response :success
    assert_select "button", text: "Add to Reading List"
  end

  test "show should display unbookmark button when bookmarked" do
    @article.bookmark!
    get article_path(@article)

    assert_response :success
    assert_select "button", text: "Remove from Reading List"
  end

  test "should bookmark article" do
    assert_not @article.bookmarked?

    post bookmark_article_path(@article)

    assert_redirected_to articles_path
    assert @article.reload.bookmarked?
  end

  test "should unbookmark article" do
    @article.create_bookmark
    assert @article.bookmarked?

    delete unbookmark_article_path(@article)

    assert_redirected_to articles_path
    assert_not @article.reload.bookmarked?
  end

  test "bookmark action should respond to JSON" do
    post bookmark_article_path(@article), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["bookmarked"]
    assert @article.reload.bookmarked?
  end

  test "unbookmark action should respond to JSON" do
    @article.create_bookmark
    assert @article.bookmarked?

    delete unbookmark_article_path(@article), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal false, json_response["bookmarked"]
    @article.reload
    assert_not @article.bookmarked?
  end

  test "should handle non-existent article gracefully" do
    get article_url(id: 999999)

    assert_redirected_to articles_path
  end

  test "should handle bookmark of non-existent article" do
    post bookmark_article_path(id: 999999)

    assert_redirected_to articles_path
  end
end
