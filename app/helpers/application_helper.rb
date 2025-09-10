module ApplicationHelper
  def safe_external_url(url)
    return nil if url.blank?

    begin
      uri = URI.parse(url)
      return url if uri.scheme&.match?(/\Ahttps?\z/) && uri.host.present?
    rescue URI::InvalidURIError
      # Invalid URI format
    end

    nil
  end
end
