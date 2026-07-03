module NewsAggregatorConfig
  def self.retention_days
    Rails.application.config_for(:news_aggregator).dig(:retention, :article_retention_days) || 30
  end
end
