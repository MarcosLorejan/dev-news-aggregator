# Database-backed source registry. When any enabled records exist,
# NewsAggregatorService uses them instead of config/news_aggregator.yml defaults.
class NewsSource < ApplicationRecord
  SOURCE_TYPES = %w[hacker_news dev_to reddit youtube].freeze

  validates :name, presence: true, uniqueness: { scope: :source_type }
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validate :reddit_subreddit_present, if: -> { source_type == "reddit" }
  validate :youtube_channel_id_present, if: -> { source_type == "youtube" }

  scope :enabled, -> { where(active: true) }

  def self.bootstrap_defaults!
    find_or_create_by!(source_type: "hacker_news", name: "Hacker News") do |source|
      source.active = true
      source.config = {}
    end

    find_or_create_by!(source_type: "dev_to", name: "Dev.to") do |source|
      source.active = true
      source.config = {}
    end

    NewsAggregatorConfig.reddit_subreddits.each do |subreddit|
      find_or_create_by!(source_type: "reddit", name: subreddit) do |source|
        source.active = true
        source.config = { "subreddit" => subreddit }
      end
    end

    NewsAggregatorConfig.youtube_channels.each do |channel|
      find_or_create_by!(source_type: "youtube", name: channel[:name]) do |source|
        source.active = true
        source.config = {
          "channel_id" => channel[:channel_id],
          "channel_name" => channel[:name]
        }
      end
    end

    retire_removed_youtube_defaults!
  end

  # Defaults we used to ship but no longer recommend (broken IDs / promo-heavy).
  RETIRED_YOUTUBE_DEFAULTS = [
    "Confreaks",
    "Google for Developers",
    "ThePrimeagen"
  ].freeze

  def self.retire_removed_youtube_defaults!
    where(source_type: "youtube", name: RETIRED_YOUTUBE_DEFAULTS, active: true).find_each do |source|
      source.update!(active: false)
    end
  end

  def subreddit
    config["subreddit"]
  end

  def channel_id
    config["channel_id"]
  end

  def channel_name
    config["channel_name"].presence || name
  end

  # Matches NewsFetchers::*#source_key used by FetchRun rows.
  def source_key
    case source_type
    when "reddit" then "reddit_#{subreddit}"
    when "youtube" then "youtube_#{channel_id}"
    else source_type
    end
  end

  def build_fetcher
    case source_type
    when "hacker_news"
      NewsFetchers::HackerNewsFetcher.new
    when "dev_to"
      NewsFetchers::DevToFetcher.new
    when "reddit"
      NewsFetchers::RedditFetcher.new(subreddit: subreddit)
    when "youtube"
      NewsFetchers::YoutubeFetcher.new(channel_id: channel_id, channel_name: channel_name)
    end
  end

  private

  def reddit_subreddit_present
    errors.add(:config, "must include subreddit") if subreddit.blank?
  end

  def youtube_channel_id_present
    errors.add(:config, "must include channel_id") if channel_id.blank?
  end
end
