# Be sure to restart your server when you modify this file.
#
# Subscribes to Rails.error so unhandled exceptions and explicit Rails.error.report
# calls emit structured logs (and optional ERROR_WEBHOOK_URL alerts).
# after_initialize ensures app/services constants are available (e.g. assets:precompile).

Rails.application.config.after_initialize do
  Rails.error.subscribe(ErrorReporting::Subscriber.new)
end
