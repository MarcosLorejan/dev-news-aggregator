module Summarizers
  class Openai < Base
    DEFAULT_URL = "https://api.openai.com/v1/chat/completions"
    DEFAULT_MODEL = "gpt-4o-mini"

    def summarize(article)
      api_key = ENV["OPENAI_API_KEY"].to_s.strip
      raise ArgumentError, "OPENAI_API_KEY is not set" if api_key.blank?

      response = HTTParty.post(
        ENV.fetch("OPENAI_API_URL", DEFAULT_URL),
        headers: {
          "Authorization" => "Bearer #{api_key}",
          "Content-Type" => "application/json"
        },
        body: {
          model: ENV.fetch("OPENAI_MODEL", DEFAULT_MODEL),
          messages: [
            { role: "system", content: "You write brief factual news summaries." },
            { role: "user", content: prompt_for(article) }
          ],
          temperature: 0.2,
          max_tokens: 220
        }.to_json,
        timeout: 30
      )

      unless response.success?
        raise "OpenAI summarizer failed with HTTP #{response.code}"
      end

      content = response.dig("choices", 0, "message", "content").to_s.strip
      raise "OpenAI summarizer returned an empty summary" if content.blank?

      content
    end
  end
end
