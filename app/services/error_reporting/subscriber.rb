module ErrorReporting
  class Subscriber
    WEBHOOK_DEDUP_TTL = 30.minutes

    def report(error, handled:, severity:, context:, source: nil)
      safe_context = normalize_context(context)
      payload = {
        "event" => "error.reported",
        "error_class" => error.class.name,
        "error_message" => error.message.to_s.truncate(500),
        "handled" => handled,
        "severity" => severity.to_s,
        "source" => source,
        "context" => safe_context,
        "reported_at" => Time.current.iso8601
      }

      log_payload(severity.to_s, payload.to_json)
      notify_webhook(error, payload) if webhook_enabled?
    rescue StandardError => e
      Rails.logger.warn({ "event" => "error.subscriber_failed", "message" => e.message }.to_json)
    end

    private

    def normalize_context(context)
      return {} unless context.is_a?(Hash)

      context.each_with_object({}) do |(key, value), memo|
        memo[key.to_s] = value
      end
    end

    def log_payload(severity, message)
      case severity
      when "error" then Rails.logger.error(message)
      when "warning" then Rails.logger.warn(message)
      else Rails.logger.info(message)
      end
    end

    def webhook_enabled?
      ENV["ERROR_WEBHOOK_URL"].present?
    end

    def notify_webhook(error, payload)
      source_key = payload.dig("context", "source_key")

      dedupe_key = [
        "error_webhook",
        payload["source"].presence || "app",
        payload["error_class"],
        source_key
      ].compact.join(":")

      return unless Rails.cache.write(dedupe_key, true, expires_in: WEBHOOK_DEDUP_TTL, unless_exist: true)

      WebhookNotifier.notify(payload.merge(
        "text" => "[dev-news-aggregator] #{error.class}: #{error.message.to_s.truncate(200)}"
      ))
    end
  end
end
