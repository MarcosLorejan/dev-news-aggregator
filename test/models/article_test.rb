require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  def setup
    @article = articles(:hacker_news_article)
  end

  test "should have one bookmark" do
    assert_respond_to @article, :bookmark
  end

  test "bookmarked? returns false when no bookmark exists" do
    assert_not @article.bookmarked?
  end

  test "bookmarked? returns true when bookmark exists" do
    @article.create_bookmark
    assert @article.bookmarked?
  end

  test "bookmark! creates a bookmark when none exists" do
    assert_not @article.bookmarked?

    bookmark = @article.bookmark!

    assert @article.bookmarked?
    assert_kind_of Bookmark, bookmark
    assert_equal @article, bookmark.article
  end

  test "bookmark! returns existing bookmark when already bookmarked" do
    existing_bookmark = @article.create_bookmark

    bookmark = @article.bookmark!

    assert_equal existing_bookmark, bookmark
    assert_equal 1, @article.reload.bookmark ? 1 : 0 # Ensure only one bookmark
  end

  test "unbookmark! destroys existing bookmark" do
    @article.create_bookmark
    assert @article.bookmarked?

    @article.unbookmark!

    assert_not @article.reload.bookmarked?
  end

  test "unbookmark! does nothing when no bookmark exists" do
    assert_not @article.bookmarked?

    assert_nothing_raised do
      @article.unbookmark!
    end

    assert_not @article.bookmarked?
  end

  test "toggle_bookmark! creates bookmark when none exists" do
    assert_not @article.bookmarked?

    @article.toggle_bookmark!

    assert @article.reload.bookmarked?
  end

  test "toggle_bookmark! removes bookmark when one exists" do
    @article.create_bookmark
    assert @article.bookmarked?

    @article.toggle_bookmark!

    assert_not @article.reload.bookmarked?
  end

  test "bookmarked scope returns only bookmarked articles" do
    bookmarked_article = articles(:dev_to_article)
    bookmarked_article.create_bookmark

    bookmarked_articles = Article.bookmarked

    assert_includes bookmarked_articles, bookmarked_article
    assert_not_includes bookmarked_articles, @article
  end

  test "not_bookmarked scope returns only non-bookmarked articles" do
    bookmarked_article = articles(:dev_to_article)
    bookmarked_article.create_bookmark

    not_bookmarked_articles = Article.not_bookmarked

    assert_includes not_bookmarked_articles, @article
    assert_not_includes not_bookmarked_articles, bookmarked_article
  end
end
