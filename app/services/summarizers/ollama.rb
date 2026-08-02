module Summarizers
  class Ollama < Base
    DEFAULT_BASE_URL = "http://127.0.0.1:11434"
    DEFAULT_MODEL = "llama3.2"

    def summarize(article)
      base_url = ENV.fetch("OLLAMA_BASE_URL", DEFAULT_BASE_URL).to_s.chomp("/")
      model = ENV.fetch("OLLAMA_MODEL", DEFAULT_MODEL)

      response = HTTParty.post(
        "#{base_url}/api/generate",
        headers: { "Content-Type" => "application/json" },
        body: {
          model: model,
          prompt: prompt_for(article),
          stream: false
        }.to_json,
        timeout: 60
      )

      unless response.success?
        raise "Ollama summarizer failed with HTTP #{response.code}"
      end

      content = response["response"].to_s.strip
      raise "Ollama summarizer returned an empty summary" if content.blank?

      content
    end
  end
end
