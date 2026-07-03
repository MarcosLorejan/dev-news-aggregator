class NewsSource < ApplicationRecord
  SOURCE_TYPES = %w[hacker_news dev_to reddit].freeze

  REDDIT_SUBREDDITS = %w[
    programming webdev javascript ruby rust
    netsec cybersecurity technology
    MachineLearning artificial LocalLLaMA
  ].freeze

  validates :name, presence: true, uniqueness: { scope: :source_type }
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validate :reddit_subreddit_present, if: -> { source_type == "reddit" }

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

    REDDIT_SUBREDDITS.each do |subreddit|
      find_or_create_by!(source_type: "reddit", name: subreddit) do |source|
        source.active = true
        source.config = { "subreddit" => subreddit }
      end
    end
  end

  def subreddit
    config["subreddit"]
  end

  def build_fetcher
    case source_type
    when "hacker_news"
      NewsFetchers::HackerNewsFetcher.new
    when "dev_to"
      NewsFetchers::DevToFetcher.new
    when "reddit"
      NewsFetchers::RedditFetcher.new(subreddit: subreddit)
    end
  end

  private

  def reddit_subreddit_present
    errors.add(:config, "must include subreddit") if subreddit.blank?
  end
end
