module ErrorReporting
  class Subscriber
    WEBHOOK_DEDUP_TTL = 30.minutes

    def report(error, handled:, severity:, context:, source: nil)
      payload = {
        event: "error.reported",
        error_class: error.class.name,
        error_message: error.message.to_s.truncate(500),
        handled: handled,
        severity: severity.to_s,
        source: source,
        context: context,
        reported_at: Time.current.iso8601
      }

      Rails.logger.public_send(log_level_for(severity[:severity]), payload.to_json)
      notify_webhook(error, payload) if webhook_enabled?
    rescue StandardError => e
      Rails.logger.warn({ event: "error.subscriber_failed", message: e.message }.to_json)
    end

    private

    def log_level_for(severity)
      case severity.to_s
      when "error" then :error
      when "warning" then :warn
      else :info
      end
    end

    def webhook_enabled?
      ENV["ERROR_WEBHOOK_URL"].present?
    end

    def notify_webhook(error, payload)
      context = payload[:context] || {}
      source_key = context[:source_key] || context["source_key"]

      dedupe_key = [
        "error_webhook",
        payload[:source].presence || "app",
        payload[:error_class],
        source_key
      ].compact.join(":")

      return unless Rails.cache.write(dedupe_key, true, expires_in: WEBHOOK_DEDUP_TTL, unless_exist: true)

      WebhookNotifier.notify(payload.merge(
        text: "[dev-news-aggregator] #{error.class}: #{error.message.to_s.truncate(200)}"
      ))
    end
  end
end
