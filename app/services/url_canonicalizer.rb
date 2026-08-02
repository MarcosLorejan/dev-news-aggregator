# Normalizes article URLs so the same story from HN / Dev.to / Reddit
# can share a cluster key despite tracking params and www differences.
class UrlCanonicalizer
  TRACKING_PARAMS = %w[
    fbclid gclid gbraid wbraid mc_cid mc_eid msclkid ref source
    _ga _gl si s feature shared
  ].freeze

  TRACKING_PREFIXES = %w[utm_].freeze

  def self.canonicalize(url)
    new(url).canonicalize
  end

  def initialize(url)
    @url = url.to_s.strip
  end

  def canonicalize
    return nil if @url.blank?

    uri = URI.parse(@url)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    host = uri.host&.downcase&.delete_prefix("www.")
    return nil if host.blank?

    path = uri.path.presence || "/"
    path = path.chomp("/")
    path = "/" if path.blank?

    query = filtered_query(uri.query)
    canonical = "#{uri.scheme.downcase}://#{host}#{path}"
    canonical = "#{canonical}?#{query}" if query.present?
    canonical
  rescue URI::InvalidURIError
    nil
  end

  private

  def filtered_query(raw_query)
    return nil if raw_query.blank?

    params = URI.decode_www_form(raw_query).reject { |key, _| tracking_param?(key) }
    return nil if params.empty?

    URI.encode_www_form(params.sort_by(&:first))
  rescue ArgumentError
    nil
  end

  def tracking_param?(key)
    name = key.to_s.downcase
    TRACKING_PARAMS.include?(name) || TRACKING_PREFIXES.any? { |prefix| name.start_with?(prefix) }
  end
end
