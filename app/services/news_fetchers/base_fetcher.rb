class NewsFetchers::BaseFetcher
  include HTTParty

  class << self
    def get(*args, **kwargs)
      parse_http_response(super)
    end

    private

    def parse_http_response(response)
      return response unless response.is_a?(HTTParty::Response)

      response.parsed_response
    rescue JSON::ParserError
      nil
    end
  end

  def initialize
    @articles = []
  end

  def fetch_articles
    raise NotImplementedError, "Subclasses must implement fetch_articles method"
  end

  protected

  def create_or_update_article(attributes)
    article = Article.find_or_initialize_by(
      external_id: attributes[:external_id],
      source_type: attributes[:source_type]
    )

    article.assign_attributes(attributes)

    if article.new_record? || article.changed?
      is_new_record = article.new_record?
      unless article.save
        Rails.logger.warn "Skipping invalid article (#{attributes[:source_type]}/#{attributes[:external_id]}): #{article.errors.full_messages.join(', ')}"
        return article
      end

      if is_new_record
        Rails.logger.info "Created article: #{article.title}"
      else
        Rails.logger.info "Updated article: #{article.title}"
      end
    end

    article
  end
end
