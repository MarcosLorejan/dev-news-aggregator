require "test_helper"

class FeedNoiseClassifierTest < ActiveSupport::TestCase
  test "flags image host urls as low signal" do
    article = Article.new(
      title: "A reasonably long meme title here",
      url: "https://i.redd.it/abc123.png",
      description: "submitted by someone",
      source_type: "reddit_artificial",
      external_id: "noise-1"
    )
    assert FeedNoiseClassifier.low_signal?(article)
  end

  test "flags very short titles as low signal" do
    article = Article.new(
      title: "lol",
      url: "https://example.com/post",
      description: "plenty of description text for a normal post",
      source_type: "hacker_news",
      external_id: "noise-2"
    )
    assert FeedNoiseClassifier.low_signal?(article)
  end

  test "keeps substantive articles as high signal" do
    article = articles(:hacker_news_article)
    assert_not FeedNoiseClassifier.low_signal?(article)
  end
end
