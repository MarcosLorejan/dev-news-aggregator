# Validates and resolves YouTube channel identifiers before saving a NewsSource.
# Accepts UC… IDs, /channel/UC… URLs, @handles, and youtube.com/@handle URLs.
# Verifies the public Atom feed responds and captures the channel title.
class YoutubeChannelValidator
  CHANNEL_ID_PATTERN = /\AUC[\w-]{20,}\z/

  Result = Struct.new(:ok, :channel_id, :channel_name, :error, keyword_init: true) do
    def valid?
      ok
    end
  end

  class << self
    def resolve(input)
      normalized = normalize(input)
      return failure("Channel ID, URL, or @handle is required") if normalized.blank?

      channel_id = extract_channel_id(normalized)
      channel_id ||= resolve_handle(normalized)

      return failure("Could not resolve YouTube channel from that input") if channel_id.blank?
      return failure("Invalid YouTube channel ID") unless CHANNEL_ID_PATTERN.match?(channel_id)

      cache_key = "youtube_channel_valid:#{channel_id}"
      cached = Rails.cache.read(cache_key)
      return Result.new(**cached.symbolize_keys) if cached.is_a?(Hash)

      feed = fetch_atom_feed(channel_id)
      unless feed[:valid]
        result = failure(feed[:error] || "YouTube channel not found or feed unavailable")
        Rails.cache.write(cache_key, result.to_h, expires_in: 15.minutes)
        return result
      end

      result = Result.new(
        ok: true,
        channel_id: channel_id,
        channel_name: feed[:title].presence || channel_id,
        error: nil
      )
      Rails.cache.write(cache_key, result.to_h, expires_in: 1.hour)
      result
    rescue StandardError => e
      failure("Could not validate YouTube channel: #{e.message}")
    end

    def normalize(input)
      input.to_s.strip
    end

    private

    def failure(message)
      Result.new(ok: false, channel_id: nil, channel_name: nil, error: message)
    end

    def extract_channel_id(value)
      return value if CHANNEL_ID_PATTERN.match?(value)

      if (match = value.match(%r{youtube\.com/channel/(UC[\w-]+)}i))
        return match[1]
      end

      nil
    end

    def resolve_handle(value)
      handle = extract_handle(value)
      return nil if handle.blank?

      resolve_handle_via_api(handle) || resolve_handle_via_page(handle)
    end

    def extract_handle(value)
      if (match = value.match(%r{youtube\.com/@([\w.-]+)}i))
        return match[1]
      end

      return nil if value.include?("/") || CHANNEL_ID_PATTERN.match?(value)

      stripped = value.delete_prefix("@")
      return stripped if stripped.match?(/\A[\w.-]{3,30}\z/i)

      nil
    end

    def resolve_handle_via_api(handle)
      api_key = ENV["YOUTUBE_API_KEY"].presence
      return nil if api_key.blank?

      response = HTTParty.get(
        "https://www.googleapis.com/youtube/v3/channels",
        query: { part: "snippet", forHandle: handle, key: api_key },
        timeout: 5
      )
      return nil unless response.success?

      item = Array(response.parsed_response["items"]).first
      item&.dig("id").presence
    rescue StandardError
      nil
    end

    def resolve_handle_via_page(handle)
      response = HTTParty.get(
        "https://www.youtube.com/@#{handle}",
        headers: { "User-Agent" => "DevNewsAggregator/1.0" },
        timeout: 8,
        follow_redirects: true
      )
      return nil unless response.success?

      body = response.body.to_s
      match = body.match(/"channelId"\s*:\s*"(UC[\w-]+)"/) ||
              body.match(%r{youtube\.com/channel/(UC[\w-]+)})
      match&.[](1)
    rescue StandardError
      nil
    end

    def fetch_atom_feed(channel_id)
      base = NewsAggregatorConfig.youtube_feed_base_url
      uri = URI.parse(base)
      response = HTTParty.get(
        "#{uri.scheme}://#{uri.host}#{uri.path}",
        query: { channel_id: channel_id },
        timeout: 5,
        headers: { "User-Agent" => "DevNewsAggregator/1.0" }
      )

      body = response.body.to_s
      unless response.code == 200 && body.include?("<feed")
        return { valid: false, error: "YouTube channel not found or feed unavailable" }
      end

      document = Nokogiri::XML(body)
      document.remove_namespaces!
      title = document.at_xpath("//author/name")&.text&.strip.presence ||
              document.at_xpath("//title")&.text&.strip.presence

      { valid: true, title: title }
    rescue StandardError => e
      { valid: false, error: e.message }
    end
  end
end
