module NewsFetchObservability
  module_function

  def log_source_outcome(run)
    payload = {
      event: "news_fetch.source_completed",
      source: run.source_key,
      status: run.status,
      articles_count: run.articles_count,
      duration_seconds: run.duration_seconds,
      finished_at: run.finished_at.iso8601
    }
    payload[:error_class] = run.error_class if run.error_class.present?
    payload[:error_message] = run.error_message if run.error_message.present?

    if run.failure?
      Rails.logger.error(payload.to_json)
    else
      Rails.logger.info(payload.to_json)
    end
  end

  def log_aggregation_completed(articles_count:, duration_seconds:, source_count:)
    Rails.logger.info({
      event: "news_fetch.completed",
      articles_count: articles_count,
      duration_seconds: duration_seconds,
      source_count: source_count,
      finished_at: Time.current.iso8601
    }.to_json)
  end
end
