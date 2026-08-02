# Builds a schema-validated unread digest payload.
# Without an LLM, themes are grouped by source category with title-only summaries.
class DigestBuilder
  PERIOD_DURATIONS = {
    "daily" => 1.day,
    "weekly" => 7.days
  }.freeze

  MAX_ARTICLES = 25

  SCHEMA_KEYS = %w[period generated_at window_start window_end themes articles].freeze
  THEME_KEYS = %w[title summary article_ids].freeze
  ARTICLE_KEYS = %w[id title url source_type score why].freeze

  def self.build!(period: "daily", at: Time.current)
    new(period: period, at: at).build!
  end

  def initialize(period: "daily", at: Time.current)
    @period = period.to_s
    raise ArgumentError, "invalid period" unless PERIOD_DURATIONS.key?(@period)

    @at = at
    @window_end = @at
    @window_start = @at - PERIOD_DURATIONS[@period]
  end

  def build!
    articles = selected_articles
    payload = validate_payload!(raw_payload(articles))
    NewsDigest.create!(
      period: @period,
      window_start: @window_start,
      window_end: @window_end,
      payload: payload
    )
  end

  private

  def selected_articles
    Article.not_read
           .not_dismissed
           .where(published_at: @window_start..@window_end)
           .order(Arel.sql("score DESC NULLS LAST"), published_at: :desc)
           .limit(MAX_ARTICLES)
           .to_a
  end

  def raw_payload(articles)
    {
      "period" => @period,
      "generated_at" => @at.iso8601,
      "window_start" => @window_start.iso8601,
      "window_end" => @window_end.iso8601,
      "themes" => themes_for(articles),
      "articles" => articles.map { |article| article_entry(article) }
    }
  end

  def themes_for(articles)
    grouped = articles.group_by { |article| category_for(article.source_type) }
    grouped.map do |category, group|
      {
        "title" => category,
        "summary" => title_only_summary(group),
        "article_ids" => group.map(&:id)
      }
    end
  end

  def title_only_summary(articles)
    titles = articles.first(3).map(&:title)
    extra = articles.size - titles.size
    base = titles.join(" · ")
    extra.positive? ? "#{base} (+#{extra} more)" : base
  end

  def article_entry(article)
    {
      "id" => article.id,
      "title" => article.title,
      "url" => article.url,
      "source_type" => article.source_type,
      "score" => article.score,
      "why" => "Unread from #{article.source_type.tr('_', ' ')}"
    }
  end

  def category_for(source_type)
    ArticlesHelper::CATEGORIES.each do |name, sources|
      return name if sources.include?(source_type)
    end
    "Other"
  end

  def validate_payload!(payload)
    raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)
    raise ArgumentError, "unexpected keys" unless (payload.keys - SCHEMA_KEYS).empty?
    raise ArgumentError, "missing keys" unless (SCHEMA_KEYS - payload.keys).empty?
    raise ArgumentError, "themes must be an Array" unless payload["themes"].is_a?(Array)
    raise ArgumentError, "articles must be an Array" unless payload["articles"].is_a?(Array)

    payload["themes"].each do |theme|
      raise ArgumentError, "invalid theme" unless theme.is_a?(Hash) && (theme.keys - THEME_KEYS).empty?
      raise ArgumentError, "theme article_ids must be an Array" unless theme["article_ids"].is_a?(Array)
    end

    payload["articles"].each do |entry|
      raise ArgumentError, "invalid article entry" unless entry.is_a?(Hash) && (entry.keys - ARTICLE_KEYS).empty?
    end

    payload
  end
end
