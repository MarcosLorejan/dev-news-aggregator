require "test_helper"

class ArticleSerializerTest < ActiveSupport::TestCase
  setup do
    @article = articles(:reddit_rust_article)
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
