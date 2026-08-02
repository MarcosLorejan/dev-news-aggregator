require "test_helper"

class ArticleSerializerTest < ActiveSupport::TestCase
  setup do
    @article = articles(:reddit_rust_article)
  end

  test "as_json includes video metadata fields" do
    @article.update!(
      content_type: "video",
      duration_seconds: 58,
      thumbnail_url: "https://i.ytimg.com/vi/x/hqdefault.jpg",
      author: "Rust Tips"
    )

    payload = ArticleSerializer.as_json(@article)

    assert_equal "video", payload[:content_type]
    assert_equal 58, payload[:duration_seconds]
    assert_equal "https://i.ytimg.com/vi/x/hqdefault.jpg", payload[:thumbnail_url]
    assert_equal "Rust Tips", payload[:author]
  end

  test "as_json omits matched_keywords when not provided" do
    payload = ArticleSerializer.as_json(@article)

    assert_not payload.key?(:matched_keywords)
  end

  test "as_json includes matched_keywords when provided" do
    payload = ArticleSerializer.as_json(@article, matched_keywords: [ "rust", "cargo" ])

    assert_equal [ "rust", "cargo" ], payload[:matched_keywords]
  end

  test "as_json includes an empty matched_keywords list when explicitly empty" do
    payload = ArticleSerializer.as_json(@article, matched_keywords: [])

    assert_equal [], payload[:matched_keywords]
  end
end
