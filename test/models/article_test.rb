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

  test "should have one read_article" do
    assert_respond_to @article, :read_article
  end

  test "should return false for read? when no read_article exists" do
    assert_not @article.read?
  end

  test "should return true for read? when read_article exists" do
    @article.create_read_article
    assert @article.read?
  end

  test "should create read_article when mark_as_read! is called and none exists" do
    assert_not @article.read?

    read_article = @article.mark_as_read!

    assert @article.read?
    assert_kind_of ReadArticle, read_article
    assert_equal @article, read_article.article
  end

  test "should return existing read_article when mark_as_read! is called and already read" do
    existing_read = @article.create_read_article

    read_article = @article.mark_as_read!

    assert_equal existing_read, read_article
    assert_equal 1, @article.reload.read_article ? 1 : 0 # Ensure only one read_article
  end

  test "should destroy existing read_article when unmark_as_read! is called" do
    @article.create_read_article
    assert @article.read?

    @article.unmark_as_read!

    assert_not @article.reload.read?
  end

  test "should do nothing when unmark_as_read! is called and no read_article exists" do
    assert_not @article.read?

    assert_nothing_raised do
      @article.unmark_as_read!
    end

    assert_not @article.read?
  end

  test "should create read_article when toggle_read! is called and none exists" do
    assert_not @article.read?

    @article.toggle_read!

    assert @article.reload.read?
  end

  test "should remove read_article when toggle_read! is called and one exists" do
    @article.create_read_article
    assert @article.read?

    @article.toggle_read!

    assert_not @article.reload.read?
  end

  test "should return only read articles in read scope" do
    read_article = articles(:dev_to_article)
    read_article.create_read_article

    read_articles = Article.read

    assert_includes read_articles, read_article
    assert_not_includes read_articles, @article
  end

  test "should return only unread articles in not_read scope" do
    read_article = articles(:dev_to_article)
    read_article.create_read_article

    unread_articles = Article.not_read

    assert_includes unread_articles, @article
    assert_not_includes unread_articles, read_article
  end

  test "should have one dismissed_article" do
    assert_respond_to @article, :dismissed_article
  end

  test "should not be dismissed initially" do
    assert_not @article.dismissed?
    assert_not @article.pending_dismissal?
  end

  test "should dismiss article" do
    dismissed = @article.dismiss!
    assert dismissed.is_a?(DismissedArticle)
    assert @article.reload.pending_dismissal?
    assert_not @article.dismissed?
  end

  test "should return existing dismissed_article when already dismissed" do
    first_dismiss = @article.dismiss!
    second_dismiss = @article.dismiss!
    assert_equal first_dismiss, second_dismiss
  end

  test "should undismiss article" do
    @article.dismiss!
    assert @article.reload.pending_dismissal?

    @article.undismiss!
    assert_not @article.reload.pending_dismissal?
    assert_not @article.dismissed?
  end

  test "should be permanently dismissed when permanent flag is true" do
    dismissed = @article.dismiss!
    dismissed.update!(permanent: true)
    assert @article.reload.dismissed?
    assert_not @article.pending_dismissal?
  end

  test "should scope not_dismissed articles" do
    dismissed_article = articles(:reddit_rust_article)
    dismissed_article.dismiss!
    dismissed_article.dismissed_article.update!(permanent: true)

    not_dismissed = Article.not_dismissed
    assert_includes not_dismissed, @article
    assert_not_includes not_dismissed, dismissed_article
  end

  test "should scope dismissed articles" do
    dismissed_article = articles(:reddit_rust_article)
    dismissed_article.dismiss!
    dismissed_article.dismissed_article.update!(permanent: true)

    dismissed = Article.dismissed
    assert_includes dismissed, dismissed_article
    assert_not_includes dismissed, @article
  end

  test "should scope pending_dismissal articles" do
    pending_article = articles(:reddit_rust_article)
    pending_article.dismiss!

    permanently_dismissed = articles(:dev_to_article)
    permanently_dismissed.dismiss!
    permanently_dismissed.dismissed_article.update!(permanent: true)

    pending = Article.pending_dismissal
    assert_includes pending, pending_article
    assert_not_includes pending, permanently_dismissed
    assert_not_includes pending, @article
  end

  test "should include temporary dismissals in not_dismissed scope" do
    temporary_dismissed = articles(:reddit_rust_article)
    temporary_dismissed.dismiss!

    not_dismissed = Article.not_dismissed
    assert_includes not_dismissed, temporary_dismissed
  end
end
