class ArticleSummarizer
  PROVIDERS = {
    "none" => Summarizers::None,
    "heuristic" => Summarizers::Heuristic,
    "openai" => Summarizers::Openai,
    "ollama" => Summarizers::Ollama
  }.freeze

  Result = Struct.new(:summary, :provider, :error, keyword_init: true)

  def self.provider_name
    name = ENV.fetch("ARTICLE_SUMMARIZER_PROVIDER", "none").to_s.strip.downcase
    PROVIDERS.key?(name) ? name : "none"
  end

  def self.enabled?
    provider_name != "none"
  end

  def self.config
    {
      enabled: enabled?,
      provider: provider_name
    }
  end

  def self.call(article, force: false)
    new(article, force: force).call
  end

  def initialize(article, force: false)
    @article = article
    @force = force
  end

  def call
    name = self.class.provider_name
    return Result.new(summary: nil, provider: name, error: "summarizer_disabled") if name == "none"

    if @article.summary.present? && !@force
      return Result.new(summary: @article.summary, provider: @article.summary_provider.presence || name, error: nil)
    end

    text = PROVIDERS.fetch(name).new.summarize(@article)
    if text.blank?
      return Result.new(summary: nil, provider: name, error: "empty_summary")
    end

    @article.update!(
      summary: text,
      summary_provider: name,
      summarized_at: Time.current
    )

    Result.new(summary: text, provider: name, error: nil)
  rescue StandardError => e
    Rails.logger.warn({
      event: "article.summarize_failed",
      article_id: @article.id,
      provider: name,
      message: e.message
    }.to_json)

    Result.new(summary: @article.summary, provider: name, error: e.message)
  end
end
