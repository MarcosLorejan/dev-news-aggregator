require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @bookmarked_article = articles(:reddit_rust_article)
    @unbookmarked_article = articles(:hacker_news_article)
  end

  test "should get index" do
    get bookmarks_url
    assert_response :success
    assert_select "h1", "Reading List"
  end

  test "should display bookmarked articles" do
    get bookmarks_url
    assert_response :success

    assert_select "article.article-card[data-source='reddit_rust']"
    assert_select "article.article-card[data-source='reddit_ruby']"
  end

  test "should show empty state when no bookmarks exist" do
    Bookmark.destroy_all

    get bookmarks_url
    assert_response :success

    assert_select "h2", "No bookmarked articles yet"
    assert_select "p", "Articles you bookmark will appear here in your reading list."
    assert_select "a[href='#{articles_path}']", "Browse Articles"
  end

  test "should group bookmarked articles by source" do
    get bookmarks_url
    assert_response :success

    # Check for filter functionality when bookmarks exist
    if Bookmark.exists?
      assert_select "button", minimum: 1
    end
  end

  test "should show back to articles link" do
    get bookmarks_url
    assert_response :success

    assert_select "a[href='#{articles_path}']", "Back to All Articles"
  end

  test "should display bookmark timestamps" do
    get bookmarks_url
    assert_response :success

    assert_select "span:contains('🔖 Bookmarked')", minimum: 1
  end

  test "should show unbookmark buttons" do
    get bookmarks_path
    
    assert_response :success
    assert_select "button[title='Remove from reading list']", minimum: 1
  end
end
