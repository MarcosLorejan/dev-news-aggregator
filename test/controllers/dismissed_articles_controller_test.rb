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
    assert_select "h1", "Dismissed Articles"
    assert_select "article.article-card", minimum: 1
  end

  test "should show dismissed articles in index" do
    get dismissed_articles_path
    
    assert_response :success
    assert assigns(:dismissed_articles).include?(@dismissed_article)
    assert_select "button", text: "Restore"
  end

  test "should show navigation links in index" do
    get dismissed_articles_path
    
    assert_response :success
    assert_select "a[href='#{articles_path}']", "Back to All Articles"
    assert_select "a[href='#{recently_dismissed_path}']", "Recently Dismissed"
  end

  test "should get recently_dismissed" do
    get recently_dismissed_path
    
    assert_response :success
    assert_select "h1", "Recently Dismissed"
  end

  test "should show recently dismissed articles" do
    get recently_dismissed_path
    
    assert_response :success
    assert assigns(:articles).include?(@recent_dismissed)
    assert_select "button", text: "Quick Restore"
  end

  test "should not show old dismissed articles in recently dismissed" do
    old_dismissed = articles(:reddit_rust_article)
    old_dismissed.dismiss!
    old_dismissed.dismissed_article.update!(dismissed_at: 2.days.ago)
    
    get recently_dismissed_path
    
    assert_response :success
    assert_not assigns(:articles).include?(old_dismissed)
  end

  test "should show navigation links in recently dismissed" do
    get recently_dismissed_path
    
    assert_response :success
    assert_select "a[href='#{articles_path}']", "Back to All Articles"
    assert_select "a[href='#{dismissed_articles_path}']", "All Dismissed"
  end

  test "should limit dismissed articles to 100" do
    get dismissed_articles_path
    
    assert_response :success
    assert_operator assigns(:dismissed_articles).count, :<=, 100
  end

  test "should limit recently dismissed articles to 10" do
    get recently_dismissed_path
    
    assert_response :success
    assert_operator assigns(:articles).count, :<=, 10
  end

  test "should order dismissed articles by dismissed_at desc" do
    newer_dismissed = articles(:reddit_ruby_article)
    newer_dismissed.dismiss!
    newer_dismissed.dismissed_article.update!(permanent: true, dismissed_at: 1.hour.ago)
    
    get dismissed_articles_path
    
    assert_response :success
    dismissed_articles = assigns(:dismissed_articles)
    assert_equal newer_dismissed, dismissed_articles.first
  end

  test "should order recently dismissed articles by dismissed_at desc" do
    newer_recent = articles(:reddit_ruby_article)
    newer_recent.dismiss!
    newer_recent.dismissed_article.update!(dismissed_at: 1.hour.ago)
    
    get recently_dismissed_path
    
    assert_response :success
    articles = assigns(:articles)
    assert_equal newer_recent, articles.first
  end
end
