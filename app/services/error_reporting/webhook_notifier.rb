module ErrorReporting
  class WebhookNotifier
    def self.notify(payload)
      url = ENV["ERROR_WEBHOOK_URL"]
      return if url.blank?

      HTTParty.post(
        url,
        body: payload.to_json,
        headers: { "Content-Type" => "application/json" },
        timeout: 5
      )
    rescue StandardError => e
      Rails.logger.warn({ event: "error.webhook_failed", message: e.message }.to_json)
    end
  end
end
