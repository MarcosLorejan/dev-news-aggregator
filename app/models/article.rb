class Article < ApplicationRecord
  validates :title, :url, :external_id, :source_type, presence: true
  validates :external_id, uniqueness: { scope: :source_type }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

  before_validation :assign_low_signal

  has_one :bookmark, dependent: :destroy
  has_one :read_article, dependent: :destroy
  has_one :dismissed_article, dependent: :destroy

  scope :bookmarked, -> { joins(:bookmark) }
  scope :not_bookmarked, -> { left_joins(:bookmark).where(bookmarks: { id: nil }) }
  scope :read, -> { joins(:read_article) }
  scope :not_read, -> { left_joins(:read_article).where(read_articles: { id: nil }) }
  scope :not_dismissed, -> { left_joins(:dismissed_article).where("dismissed_articles.id IS NULL OR dismissed_articles.permanent = false") }
  scope :dismissed, -> { joins(:dismissed_article).where(dismissed_articles: { permanent: true }) }
  scope :pending_dismissal, -> { joins(:dismissed_article).where(dismissed_articles: { permanent: false }) }
  scope :search, ->(query) {
    q = query.to_s.strip
    if q.blank?
      all
    else
      pattern = "%#{sanitize_sql_like(q)}%"
      where("title ILIKE :q OR COALESCE(description, '') ILIKE :q", q: pattern)
    end
  }

  def bookmarked?
    bookmark.present?
  end

  def bookmark!
    record = Bookmark.find_or_create_by!(article_id: id) do |bookmark|
      bookmark.bookmarked_at = Time.current
    end
    association(:bookmark).target = record
    record
  rescue ActiveRecord::RecordNotUnique
    reload.bookmark
  end

  def unbookmark!
    if bookmark
      bookmark.destroy
      reload
    end
  end

  def toggle_bookmark!
    return unbookmark! if bookmarked?
    bookmark!
  end

  def read?
    read_article.present?
  end

  def mark_as_read!
    record = ReadArticle.find_or_create_by!(article_id: id) do |read_article|
      read_article.read_at = Time.current
    end
    association(:read_article).target = record
    record
  rescue ActiveRecord::RecordNotUnique
    reload.read_article
  end

  def unmark_as_read!
    if read_article
      read_article.destroy
      reload
    end
  end

  def toggle_read!
    return unmark_as_read! if read?
    mark_as_read!
  end

  def dismissed?
    dismissed_article&.permanent?
  end

  def pending_dismissal?
    dismissed_article.present? && !dismissed_article.permanent?
  end

  def dismiss!
    record = DismissedArticle.find_or_create_by!(article_id: id) do |dismissed_article|
      dismissed_article.dismissed_at = Time.current
      dismissed_article.permanent = false
    end
    association(:dismissed_article).target = record
    record
  rescue ActiveRecord::RecordNotUnique
    reload.dismissed_article
  end

  def undismiss!
    if dismissed_article
      dismissed_article.destroy
      reload
    end
  end

  private

  def assign_low_signal
    self.low_signal = FeedNoiseClassifier.low_signal?(self)
  end
end
