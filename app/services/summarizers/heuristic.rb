module Summarizers
  # Offline extractive summarizer — no network, safe for CI and default local use.
  class Heuristic < Base
    MAX_LENGTH = 400

    def summarize(article)
      body = article.description.to_s.strip
      text = if body.present?
        body.split(/(?<=[.!?])\s+/).first(2).join(" ")
      else
        "#{article.title} — from #{humanize_source(article.source_type)}."
      end

      text.to_s.squish.truncate(MAX_LENGTH).presence
    end

    private

    def humanize_source(source_type)
      source_type.to_s.tr("_", " ")
    end
  end
end
