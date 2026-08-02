# Heuristic classifier for low-signal / meme-like feed noise.
# Used to demote items in default ranking without deleting them.
class FeedNoiseClassifier
  IMAGE_HOSTS = %w[
    i.redd.it
    preview.redd.it
    i.imgur.com
    imgur.com
    media.giphy.com
    giphy.com
    pbs.twimg.com
  ].freeze

  MEME_HOSTS = %w[
    knowyourmeme.com
    memegenerator.net
    imgflip.com
  ].freeze

  MIN_TITLE_LENGTH = 12

  def self.low_signal?(article)
    new(article).low_signal?
  end

  def initialize(article)
    @article = article
  end

  def low_signal?
    image_only_url? || meme_host? || short_title? || thin_reddit_image_post?
  end

  private

  def image_only_url?
    host = host_for(@article.url)
    return false if host.blank?

    IMAGE_HOSTS.include?(host) || image_path?(@article.url)
  end

  def meme_host?
    host = host_for(@article.url)
    host.present? && MEME_HOSTS.include?(host)
  end

  def short_title?
    @article.title.to_s.gsub(/\s+/, " ").strip.length < MIN_TITLE_LENGTH
  end

  def thin_reddit_image_post?
    return false unless @article.source_type.to_s.start_with?("reddit_")

    description = @article.description.to_s.strip
    return false if description.length >= 80

    image_only_url?
  end

  def host_for(url)
    URI.parse(url.to_s).host&.downcase&.delete_prefix("www.")
  rescue URI::InvalidURIError
    nil
  end

  def image_path?(url)
    path = URI.parse(url.to_s).path.to_s.downcase
    path.match?(/\.(png|jpe?g|gif|webp|bmp)(\z|\?)/)
  rescue URI::InvalidURIError
    false
  end
end
