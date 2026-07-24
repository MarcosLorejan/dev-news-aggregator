# Be sure to restart your server when you modify this file.
#
# Global and mutating-request throttles for public deployments.
# Skipped in development so local UI usage is never blocked.
# Complements ArticlesController#fetch (1 request / 2 minutes per IP).

Rack::Attack.enabled = !Rails.env.development?

if Rails.env.test?
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
end

class Rack::Attack
  GLOBAL_LIMIT = Integer(ENV.fetch("RACK_ATTACK_GLOBAL_LIMIT", "300"))
  GLOBAL_PERIOD = Integer(ENV.fetch("RACK_ATTACK_GLOBAL_PERIOD", "300"))
  MUTATE_LIMIT = Integer(ENV.fetch("RACK_ATTACK_MUTATE_LIMIT", "60"))
  MUTATE_PERIOD = Integer(ENV.fetch("RACK_ATTACK_MUTATE_PERIOD", "60"))

  safelist("healthcheck") do |request|
    request.path == "/up"
  end

  throttle("req/ip", limit: GLOBAL_LIMIT, period: GLOBAL_PERIOD) do |request|
    request.ip
  end

  throttle("mutations/ip", limit: MUTATE_LIMIT, period: MUTATE_PERIOD) do |request|
    request.ip if request.post? || request.patch? || request.put? || request.delete?
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    now = match_data[:epoch_time] || Time.now.to_i
    period = match_data[:period] || MUTATE_PERIOD
    retry_after = period - (now % period)

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ { error: "Rate limit exceeded. Please try again later." }.to_json ]
    ]
  end
end
