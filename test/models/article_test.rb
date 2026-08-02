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

  test "bookmark! recovers from RecordNotUnique race" do
    existing_bookmark = @article.create_bookmark
    article = Article.find(@article.id)
    Bookmark.define_singleton_method(:find_or_create_by!) do |*_args, **_kwargs, &_block|
      raise ActiveRecord::RecordNotUnique, "duplicate"
    end

    assert_equal existing_bookmark, article.bookmark!
  ensure
    Bookmark.singleton_class.remove_method(:find_or_create_by!)
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

  test "mark_as_read! recovers from RecordNotUnique race" do
    existing_read = @article.create_read_article
    article = Article.find(@article.id)
    ReadArticle.define_singleton_method(:find_or_create_by!) do |*_args, **_kwargs, &_block|
      raise ActiveRecord::RecordNotUnique, "duplicate"
    end

    assert_equal existing_read, article.mark_as_read!
  ensure
    ReadArticle.singleton_class.remove_method(:find_or_create_by!)
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

  test "dismiss! recovers from RecordNotUnique race" do
    existing_dismissed = @article.dismiss!
    article = Article.find(@article.id)
    DismissedArticle.define_singleton_method(:find_or_create_by!) do |*_args, **_kwargs, &_block|
      raise ActiveRecord::RecordNotUnique, "duplicate"
    end

    assert_equal existing_dismissed, article.dismiss!
  ensure
    DismissedArticle.singleton_class.remove_method(:find_or_create_by!)
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

  test "requires title url external_id and source_type" do
    article = Article.new
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
    assert_includes article.errors[:url], "can't be blank"
    assert_includes article.errors[:external_id], "can't be blank"
    assert_includes article.errors[:source_type], "can't be blank"
  end

  test "requires unique external_id per source_type" do
    duplicate = Article.new(
      title: "Duplicate",
      url: "https://example.com/dup",
      external_id: @article.external_id,
      source_type: @article.source_type,
      published_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_id], "has already been taken"
  end

  test "rejects invalid URLs" do
    article = Article.new(
      title: "Bad URL",
      url: "not-a-url",
      external_id: "bad-url",
      source_type: "test",
      published_at: Time.current
    )

    assert_not article.valid?
    assert_includes article.errors[:url], "is invalid"
  end

  test "search returns all articles when query is blank" do
    assert_equal Article.count, Article.search("").count
    assert_equal Article.count, Article.search("   ").count
    assert_equal Article.count, Article.search(nil).count
  end

  test "search matches title and description case-insensitively" do
    titles = Article.search("rust").pluck(:title)
    assert_includes titles, articles(:reddit_rust_article).title
    assert_not_includes titles, articles(:hacker_news_article).title

    titles = Article.search("cleaner").pluck(:title)
    assert_includes titles, articles(:dev_to_article).title
  end

  test "search escapes LIKE wildcards in the query" do
    Article.create!(
      title: "100% coverage tips",
      url: "https://example.com/coverage",
      external_id: "coverage-percent",
      source_type: "hacker_news",
      published_at: Time.current,
      description: "literal percent"
    )

    titles = Article.search("100%").pluck(:title)
    assert_includes titles, "100% coverage tips"
    assert_equal 1, titles.size
  end

  test "search matches fuzzy title via trigram" do
    @article.update!(title: "Learning Rust concurrency patterns")
    results = Article.search("Rust concurrency")
    assert_includes results, @article
  end

  test "matching_keywords returns all articles when no usable term is given" do
    assert_equal Article.count, Article.matching_keywords(nil).count
    assert_equal Article.count, Article.matching_keywords("").count
    assert_equal Article.count, Article.matching_keywords(" , ,  ").count
    assert_equal Article.count, Article.matching_keywords([]).count
  end

  test "matching_keywords with any match returns articles hitting either term" do
    results = Article.matching_keywords("ruby,rust")

    assert_includes results, articles(:dev_to_article)
    assert_includes results, articles(:reddit_rust_article)
    assert_not_includes results, articles(:hacker_news_article)
  end

  test "matching_keywords with all match requires every term" do
    both = articles(:reddit_ruby_article)
    both.update!(description: "Exploring the latest Rails features and their performance impact")

    results = Article.matching_keywords("rails,performance", match: :all)

    assert_includes results, both
    assert_not_includes results, articles(:reddit_rust_article)
  end

  test "matching_keywords treats multi-word terms as phrases" do
    architecture = Article.create!(
      title: "Notes on software architecture reviews",
      url: "https://example.com/architecture",
      external_id: "architecture-1",
      source_type: "hacker_news",
      published_at: Time.current,
      description: "Trade-offs in layered designs"
    )
    Article.create!(
      title: "Software testing without architecture talk",
      url: "https://example.com/testing",
      external_id: "testing-1",
      source_type: "hacker_news",
      published_at: Time.current,
      description: "Only the two words apart"
    )

    results = Article.matching_keywords("software architecture")

    assert_equal [ architecture ], results.to_a
  end

  test "matching_keywords ignores duplicate terms regardless of case" do
    assert_equal(
      Article.matching_keywords("ruby").pluck(:id).sort,
      Article.matching_keywords("ruby,Ruby, RUBY ").pluck(:id).sort
    )
  end

  test "matching_keywords caps the number of terms" do
    filler = (1..Article::MAX_KEYWORDS).map { |index| "no-match-#{index}" }

    results = Article.matching_keywords(filler + [ "rust" ])

    assert_not_includes results, articles(:reddit_rust_article)
  end

  test "matching_keywords escapes LIKE wildcards" do
    literal = Article.create!(
      title: "Ship 100% typed Ruby",
      url: "https://example.com/typed",
      external_id: "typed-1",
      source_type: "dev_to",
      published_at: Time.current,
      description: "literal percent"
    )

    assert_equal [ literal ], Article.matching_keywords("100%").to_a
  end

  test "similar_to returns title-similar articles" do
    related = articles(:dev_to_article)
    @article.update!(title: "Rails performance tips for production")
    related.update!(title: "Rails performance tips and tricks")

    similar = Article.similar_to(@article)
    assert_includes similar, related
    assert_not_includes similar, @article
  end
end
