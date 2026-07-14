class NewsFetchers::BaseFetcher
  include HTTParty

  class FetchError < StandardError; end

  RETRYABLE_ERRORS = [
    Net::OpenTimeout,
    Net::ReadTimeout,
    Errno::ECONNRESET,
    Errno::ETIMEDOUT,
    SocketError
  ].freeze

  class << self
    def get(*args, **kwargs)
      kwargs[:timeout] = NewsAggregatorConfig.request_timeout unless kwargs.key?(:timeout)

      attempt = 0
      max_attempts = NewsAggregatorConfig.max_retries + 1

      begin
        parse_http_response(super(*args, **kwargs))
      rescue *RETRYABLE_ERRORS
        attempt += 1
        raise if attempt >= max_attempts

        sleep(2**(attempt - 1))
        retry
      end
    end

    private

    def parse_http_response(response)
      return response unless response.is_a?(HTTParty::Response)

      unless response.success?
        body_preview = response.body.to_s.gsub(/\s+/, " ").strip[0, 200]
        raise FetchError,
              "HTTP #{response.code} for #{response.request&.uri}: #{body_preview.presence || '(empty body)'}"
      end

      response.parsed_response
    rescue JSON::ParserError => e
      raise FetchError, "Invalid JSON response: #{e.message}"
    end
  end

  def initialize
    @articles = []
  end

  def source_key
    self.class.name.demodulize.delete_suffix("Fetcher").underscore
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
