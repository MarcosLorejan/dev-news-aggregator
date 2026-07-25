require "test_helper"

class ArticleTopicClassifierTest < ActiveSupport::TestCase
  test "returns schema-validated tags from keywords" do
    article = Article.new(
      title: "Local LLM agents and RAG on consumer hardware",
      description: "Running ollama with embeddings",
      source_type: "hacker_news",
      url: "https://example.com/a",
      external_id: "cls-1"
    )

    payload = ArticleTopicClassifier.classify(article)
    assert_includes payload["tags"], "local-llm"
    assert_includes payload["tags"], "agents"
    assert_includes payload["tags"], "rag"
    assert_empty payload["tags"] - ArticleTopicClassifier::ALLOWED_SLUGS
  end

  test "apply! persists tags for matching articles" do
    article = articles(:hacker_news_article)
    article.update!(title: "Rust security CVE-2024-1 exploit writeup")

    slugs = article.reload.tags.map(&:slug)
    assert_includes slugs, "rust"
    assert_includes slugs, "security"
  end

  test "classify returns empty tags when payload fails schema validation" do
    article = Article.new(
      title: "x",
      description: "y",
      source_type: "dev_to",
      url: "https://example.com/b",
      external_id: "cls-2"
    )
    classifier = ArticleTopicClassifier.new(article)
    classifier.define_singleton_method(:raw_payload) do
      { "tags" => [ "nope" ], "extra" => true }
    end

    assert_equal({ "tags" => [] }, classifier.classify)
  end
end
