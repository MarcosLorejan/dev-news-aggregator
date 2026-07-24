require "test_helper"

class PersonalFeedRankerTest < ActiveSupport::TestCase
  setup do
    @hn = articles(:hacker_news_article)
    @dev_to = articles(:dev_to_article)
    @rust = articles(:reddit_rust_article)
    @ruby = articles(:reddit_ruby_article)
  end

  test "cold start orders by published_at desc" do
    Bookmark.delete_all
    DismissedArticle.delete_all

    ids = PersonalFeedRanker.apply(Article.all).pluck(:id)
    expected = Article.order(published_at: :desc).pluck(:id)
    assert_equal expected, ids
  end

  test "boosts bookmarked source types ahead of others" do
    # Fixtures already bookmark rust + ruby. Clear dismissals.
    DismissedArticle.delete_all

    ids = PersonalFeedRanker.apply(Article.all).pluck(:id)

    rust_index = ids.index(@rust.id)
    ruby_index = ids.index(@ruby.id)
    hn_index = ids.index(@hn.id)
    dev_to_index = ids.index(@dev_to.id)

    assert rust_index < hn_index
    assert ruby_index < hn_index
    assert rust_index < dev_to_index
    assert ruby_index < dev_to_index
    # Among boosted sources, higher score wins (rust 200 > ruby 89).
    assert rust_index < ruby_index
  end

  test "demotes permanently dismissed source types" do
    Bookmark.delete_all
    DismissedArticle.delete_all
    @hn.bookmark!
    DismissedArticle.create!(
      article: @rust,
      dismissed_at: Time.current,
      permanent: true
    )

    # Another rust article should rank below hn due to source demotion.
    other_rust = Article.create!(
      title: "Another Rust post",
      url: "https://example.com/other-rust",
      external_id: "other-rust-1",
      source_type: "reddit_rust",
      published_at: Time.current,
      score: 999,
      comment_count: 0,
      description: "high score but dismissed source"
    )

    ids = PersonalFeedRanker.apply(Article.all).pluck(:id)
    assert ids.index(@hn.id) < ids.index(other_rust.id)
  end
end
