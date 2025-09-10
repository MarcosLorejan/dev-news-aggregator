require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  def setup
    @article = articles(:hacker_news_article)
    @bookmark = Bookmark.new(article: @article)
  end

  test "should belong to article" do
    assert_respond_to @bookmark, :article
    assert_equal @article, @bookmark.article
  end

  test "should be valid with valid attributes" do
    assert @bookmark.valid?
  end

  test "should require article" do
    @bookmark.article = nil
    assert_not @bookmark.valid?
    assert_includes @bookmark.errors[:article_id], "can't be blank"
  end

  test "should validate uniqueness of article_id" do
    @bookmark.save!

    duplicate_bookmark = Bookmark.new(article: @article)
    assert_not duplicate_bookmark.valid?
    assert_includes duplicate_bookmark.errors[:article_id], "has already been taken"
  end

  test "should set bookmarked_at before create" do
    freeze_time = Time.parse("2025-01-01 12:00:00 UTC")

    Timecop.freeze(freeze_time) do
      @bookmark.save!
      assert_equal freeze_time, @bookmark.bookmarked_at
    end
  end

  test "should not override manually set bookmarked_at" do
    custom_time = Time.parse("2024-12-31 10:00:00 UTC")
    @bookmark.bookmarked_at = custom_time
    @bookmark.save!

    assert_equal custom_time, @bookmark.bookmarked_at
  end

  test "recent scope should order by bookmarked_at desc" do
    # Clear existing bookmarks and create new ones with specific times
    Bookmark.destroy_all

    old_bookmark = Bookmark.create!(article: articles(:dev_to_article), bookmarked_at: 2.days.ago)
    new_bookmark = Bookmark.create!(article: articles(:hacker_news_article), bookmarked_at: 1.day.ago)

    recent_bookmarks = Bookmark.recent

    assert_equal [ new_bookmark, old_bookmark ], recent_bookmarks.to_a
  end

  test "should destroy bookmark when article is destroyed" do
    @bookmark.save!
    bookmark_id = @bookmark.id

    @article.destroy

    assert_not Bookmark.exists?(bookmark_id)
  end
end
