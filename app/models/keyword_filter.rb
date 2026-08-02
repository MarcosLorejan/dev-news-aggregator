# Saved keyword presets ("interests") used to filter the feed by topic instead of source.
# Defaults come from config/news_aggregator.yml and are seeded once, like NewsSource.
class KeywordFilter < ApplicationRecord
  MAX_TERM_LENGTH = 60

  before_validation :assign_slug
  before_validation :normalize_terms

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true
  validate :terms_present
  validate :terms_within_length

  scope :enabled, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  def self.slug_for(name)
    name.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
  end

  # Idempotent: existing interests are left untouched so local edits survive re-seeding.
  def self.bootstrap_defaults!
    NewsAggregatorConfig.interests.each_with_index do |interest, index|
      next if exists?(slug: slug_for(interest[:name]))

      create!(
        name: interest[:name],
        terms: Array(interest[:terms]),
        active: true,
        position: index
      )
    end
  end

  private

  def assign_slug
    self.slug = self.class.slug_for(name) if name.present?
  end

  # Same normalization as the keywords index filter: trim, downcase, dedupe, cap.
  def normalize_terms
    self.terms = Article.normalize_keywords(Array(terms).map { |term| term.to_s.downcase })
  end

  def terms_present
    errors.add(:terms, "must include at least one keyword") if terms.empty?
  end

  def terms_within_length
    return if terms.all? { |term| term.length <= MAX_TERM_LENGTH }

    errors.add(:terms, "must be #{MAX_TERM_LENGTH} characters or fewer each")
  end
end
