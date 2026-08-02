require "test_helper"

class ArticleSummarizerTest < ActiveSupport::TestCase
  setup do
    @article = articles(:hacker_news_article)
    @previous_provider = ENV["ARTICLE_SUMMARIZER_PROVIDER"]
    @previous_openai_key = ENV["OPENAI_API_KEY"]
    @previous_openai_url = ENV["OPENAI_API_URL"]
    @previous_ollama_url = ENV["OLLAMA_BASE_URL"]
    ENV.delete("ARTICLE_SUMMARIZER_PROVIDER")
    ENV.delete("OPENAI_API_KEY")
    ENV.delete("OPENAI_API_URL")
    ENV.delete("OLLAMA_BASE_URL")
  end

  teardown do
    restore_env("ARTICLE_SUMMARIZER_PROVIDER", @previous_provider)
    restore_env("OPENAI_API_KEY", @previous_openai_key)
    restore_env("OPENAI_API_URL", @previous_openai_url)
    restore_env("OLLAMA_BASE_URL", @previous_ollama_url)
    @article.update!(summary: nil, summary_provider: nil, summarized_at: nil)
  end

  test "disabled by default" do
    refute ArticleSummarizer.enabled?
    assert_equal "none", ArticleSummarizer.provider_name

    result = ArticleSummarizer.call(@article)
    assert_nil result.summary
    assert_equal "summarizer_disabled", result.error
    assert_nil @article.reload.summary
  end

  test "heuristic provider caches summary without network" do
    ENV["ARTICLE_SUMMARIZER_PROVIDER"] = "heuristic"

    result = ArticleSummarizer.call(@article)

    assert_nil result.error
    assert_equal "heuristic", result.provider
    assert_includes result.summary, "amazing product"
    assert_equal result.summary, @article.reload.summary
    assert_equal "heuristic", @article.summary_provider
    assert_not_nil @article.summarized_at
  end

  test "returns cached summary unless forced" do
    ENV["ARTICLE_SUMMARIZER_PROVIDER"] = "heuristic"
    @article.update!(
      summary: "Cached summary",
      summary_provider: "heuristic",
      summarized_at: 1.hour.ago
    )

    result = ArticleSummarizer.call(@article)
    assert_equal "Cached summary", result.summary

    forced = ArticleSummarizer.call(@article, force: true)
    assert_includes forced.summary, "amazing product"
    refute_equal "Cached summary", @article.reload.summary
  end

  test "openai provider posts to chat completions" do
    ENV["ARTICLE_SUMMARIZER_PROVIDER"] = "openai"
    ENV["OPENAI_API_KEY"] = "test-key"
    ENV["OPENAI_API_URL"] = "https://api.openai.com/v1/chat/completions"

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with { |req| req.headers["Authorization"] == "Bearer test-key" }
      .to_return(
        status: 200,
        body: {
          choices: [ { message: { content: "Cloud summary of the startup." } } ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = ArticleSummarizer.call(@article)

    assert_nil result.error
    assert_equal "openai", result.provider
    assert_equal "Cloud summary of the startup.", result.summary
    assert_equal "openai", @article.reload.summary_provider
  end

  test "openai provider failures do not raise" do
    ENV["ARTICLE_SUMMARIZER_PROVIDER"] = "openai"
    ENV["OPENAI_API_KEY"] = "test-key"

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 500, body: "nope")

    result = ArticleSummarizer.call(@article)

    assert_nil result.summary
    assert_match(/OpenAI summarizer failed/, result.error)
    assert_nil @article.reload.summary
  end

  test "ollama provider posts to local generate endpoint" do
    ENV["ARTICLE_SUMMARIZER_PROVIDER"] = "ollama"
    ENV["OLLAMA_BASE_URL"] = "http://127.0.0.1:11434"

    stub_request(:post, "http://127.0.0.1:11434/api/generate")
      .to_return(
        status: 200,
        body: { response: "Local model summary." }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = ArticleSummarizer.call(@article)

    assert_nil result.error
    assert_equal "ollama", result.provider
    assert_equal "Local model summary.", result.summary
  end

  test "unknown provider falls back to none" do
    ENV["ARTICLE_SUMMARIZER_PROVIDER"] = "made_up"
    assert_equal "none", ArticleSummarizer.provider_name
    refute ArticleSummarizer.enabled?
  end

  private

  def restore_env(key, value)
    if value
      ENV[key] = value
    else
      ENV.delete(key)
    end
  end
end
