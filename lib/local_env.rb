# frozen_string_literal: true

# Loads allowlisted KEY=VALUE pairs from a local `.env` into ENV when unset.
# Rails has no dotenv gem; Docker Compose reads `.env` for Postgres only.
# See docs/DEVELOPMENT.md (Environment configuration).
module LocalEnv
  ROOT = File.expand_path("..", __dir__)
  DEFAULT_PATH = File.join(ROOT, ".env")

  # Optional app secrets / toggles documented in `.env.example`.
  # Postgres keys are listed so `bin/dev` / `dev.ps1` can expose them to Rails
  # when pointing at a non-default DB; Compose still reads `.env` for the container.
  ALLOWLIST = %w[
    POSTGRES_USER
    POSTGRES_PASSWORD
    POSTGRES_DB
    DB_HOST
    DB_PORT
    DB_USERNAME
    DB_PASSWORD
    SECRET_KEY_BASE
    APP_HOSTS
    MUTATING_AUTH_USERNAME
    MUTATING_AUTH_PASSWORD
    ERROR_WEBHOOK_URL
    REDDIT_CLIENT_ID
    REDDIT_CLIENT_SECRET
    YOUTUBE_API_KEY
    ARTICLE_SUMMARIZER_PROVIDER
    OPENAI_API_KEY
    OPENAI_API_URL
    OPENAI_MODEL
    OLLAMA_BASE_URL
    OLLAMA_MODEL
  ].freeze

  module_function

  def load!(path: DEFAULT_PATH, overwrite: false)
    return 0 unless File.file?(path)

    loaded = 0
    File.foreach(path, encoding: "UTF-8") do |raw|
      line = raw.strip
      next if line.empty? || line.start_with?("#")

      key, value = line.split("=", 2)
      next if key.nil? || value.nil?

      key = key.strip
      next unless ALLOWLIST.include?(key)
      next if !overwrite && env_set?(key)

      ENV[key] = unquote(value.strip)
      loaded += 1
    end
    loaded
  end

  def env_set?(key)
    value = ENV[key]
    !(value.nil? || value.to_s.strip.empty?)
  end

  def unquote(value)
    if (value.start_with?('"') && value.end_with?('"')) ||
       (value.start_with?("'") && value.end_with?("'"))
      return value[1..-2]
    end

    value
  end

  def present_masked(key)
    value = ENV[key].to_s
    return { key: key, present: false, length: 0 } if value.strip.empty?

    { key: key, present: true, length: value.length }
  end
end
