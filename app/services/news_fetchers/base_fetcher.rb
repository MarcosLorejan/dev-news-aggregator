class NewsFetchers::BaseFetcher
  include HTTParty

  class FetchError < StandardError; end

  class RateLimitedError < FetchError
    attr_reader :http_status, :retry_after_seconds

    def initialize(message, http_status:, retry_after_seconds: nil)
      super(message)
      @http_status = http_status
      @retry_after_seconds = retry_after_seconds
    end
  end

  RETRYABLE_ERRORS = [
    Net::OpenTimeout,
    Net::ReadTimeout,
    Errno::ECONNRESET,
    Errno::ETIMEDOUT,
    SocketError
  ].freeze

  class << self
    attr_writer :retry_jitter_factor

    def retry_jitter_factor
      @retry_jitter_factor.nil? ? 0.25 : @retry_jitter_factor
    end

    def with_jitter(seconds, factor: retry_jitter_factor)
      base = seconds.to_f
      return 0.0 if base <= 0

      jitter = factor.to_f
      return base if jitter <= 0

      base + (rand * jitter * base)
    end

    def get(*args, **kwargs)
      kwargs[:timeout] = NewsAggregatorConfig.request_timeout unless kwargs.key?(:timeout)

      attempt = 0
      max_attempts = NewsAggregatorConfig.max_retries + 1

      begin
        parse_http_response(super(*args, **kwargs))
      rescue *RETRYABLE_ERRORS
        attempt += 1
        raise if attempt >= max_attempts

        Kernel.sleep(with_jitter(2**(attempt - 1)))
        retry
      end
    end

    def parse_retry_after_seconds(response)
      headers = http_headers(response)
      retry_after = header_value(headers, "Retry-After")
      if retry_after.present?
        return retry_after.to_f if retry_after.to_s.match?(/\A\d+(\.\d+)?\z/)

        begin
          return [ Time.httpdate(retry_after.to_s) - Time.now, 0 ].max
        rescue ArgumentError
          # Fall through to x-ratelimit-reset.
        end
      end

      reset = header_value(headers, "x-ratelimit-reset")
      return nil if reset.blank?

      value = reset.to_f
      return nil if value <= 0

      # Absolute unix timestamp vs relative seconds-until-reset.
      if value > 1_000_000_000
        [ value - Time.now.to_f, 0 ].max
      else
        value
      end
    end

    private

    def parse_http_response(response)
      return response unless response.is_a?(HTTParty::Response)

      unless response.success?
        body_preview = response.body.to_s.gsub(/\s+/, " ").strip[0, 200]
        message = "HTTP #{response.code} for #{response.request&.uri}: #{body_preview.presence || '(empty body)'}"
        code = response.code.to_i

        if code == 429
          raise RateLimitedError.new(
            message,
            http_status: code,
            retry_after_seconds: parse_retry_after_seconds(response)
          )
        end

        raise FetchError, message
      end

      response.parsed_response
    rescue JSON::ParserError => e
      raise FetchError, "Invalid JSON response: #{e.message}"
    end

    def http_headers(response)
      return {} unless response.respond_to?(:headers)

      response.headers || {}
    end

    def header_value(headers, name)
      return nil if headers.blank?

      if headers.respond_to?(:[])
        value = headers[name] || headers[name.downcase] || headers[name.upcase]
        return Array(value).first if value
      end

      headers.each do |key, value|
        return Array(value).first if key.to_s.casecmp?(name)
      end

      nil
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
