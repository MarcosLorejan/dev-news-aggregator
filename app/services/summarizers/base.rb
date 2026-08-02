module Summarizers
  class Base
    # Returns a short plain-text summary, or raises on hard failure.
    def summarize(article)
      raise NotImplementedError, "#{self.class} must implement #summarize"
    end

    private

    def prompt_for(article)
      description = article.description.to_s.strip
      description = "(no description)" if description.blank?

      <<~PROMPT.strip
        Summarize this developer news article in 2-3 concise sentences.
        Focus on what was announced or discussed and why it matters.
        Do not invent facts beyond the provided text.

        Title: #{article.title}
        Source: #{article.source_type}
        URL: #{article.url}
        Description: #{description}
      PROMPT
    end
  end
end
