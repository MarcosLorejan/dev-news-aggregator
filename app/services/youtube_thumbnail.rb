# Prefer higher-res YouTube stills. Atom feeds usually ship hqdefault; maxres may 404
# for some videos — the UI falls back down the quality ladder on image error.
class YoutubeThumbnail
  HOST = "https://i.ytimg.com"

  def self.preferred_url(thumbnail_url = nil, video_id: nil)
    id = video_id.to_s.strip.presence || extract_video_id(thumbnail_url)
    return thumbnail_url.presence if id.blank?

    "#{HOST}/vi/#{id}/maxresdefault.jpg"
  end

  def self.extract_video_id(url)
    return if url.blank?

    url.to_s[%r{/vi/([^/]+)/}, 1].presence ||
      url.to_s[/[?&]v=([^&]+)/, 1].presence
  end
end
