class Article < ApplicationRecord
  # Keeps keyword queries bounded no matter how long a saved interest preset grows.
  MAX_KEYWORDS = 20

  validates :title, :url, :external_id, :source_type, presence: true
  validates :external_id, uniqueness: { scope: :source_type }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

  before_validation :assign_canonical_url
  before_validation :assign_low_signal
  after_commit :refresh_topic_tags, on: %i[create update]

  has_one :bookmark, dependent: :destroy
  has_one :read_article, dependent: :destroy
  has_one :dismissed_article, dependent: :destroy
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

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
      where(
        "title ILIKE :pattern OR COALESCE(description, '') ILIKE :pattern OR " \
        "similarity(title, :q) > 0.12 OR similarity(COALESCE(description, ''), :q) > 0.1",
        pattern: pattern,
        q: q
      )
    end
  }
  scope :with_topic_tag, ->(slug) {
    return all if slug.blank?

    joins(:tags).where(tags: { slug: slug }).distinct
  }
  scope :matching_keywords, ->(terms, match: :any) {
    clause = Article.keyword_clause(terms, match: match)
    clause ? where(clause) : all
  }

  # Accepts a comma-separated string or an array; multi-word terms stay whole phrases.
  def self.normalize_keywords(terms)
    list = terms.is_a?(String) ? terms.split(",") : Array(terms)

    list.map { |term| term.to_s.strip }
        .reject(&:blank?)
        .uniq { |term| term.downcase }
        .first(MAX_KEYWORDS)
  end

  # Sanitized SQL fragment for the given terms, or nil when there is nothing to match.
  def self.keyword_clause(terms, match: :any)
    keywords = normalize_keywords(terms)
    return nil if keywords.empty?

    joiner = match.to_s == "all" ? " AND " : " OR "
    keywords.map { |keyword|
      pattern = "%#{sanitize_sql_like(keyword)}%"
      sanitize_sql_array([ "(title ILIKE ? OR COALESCE(description, '') ILIKE ?)", pattern, pattern ])
    }.join(joiner)
  end

  # Conditional counts in one query, so listing N keyword presets stays a single round trip.
  def self.keyword_match_counts(term_groups, scope: all)
    return [] if term_groups.empty?

    projections = term_groups.each_with_index.map { |terms, index|
      "COUNT(CASE WHEN #{keyword_clause(terms) || 'FALSE'} THEN 1 END) AS keyword_count_#{index}"
    }

    row = scope.unscope(:includes, :order, :select, :limit, :offset).select(projections.join(", ")).take

    term_groups.each_index.map { |index| row.public_send("keyword_count_#{index}").to_i }
  end

  def self.similar_to(article, limit: 5)
    title = article.title.to_s.strip
    return none if title.blank?

    where.not(id: article.id)
      .where("similarity(title, ?) > 0.15", title)
      .order(Arel.sql(sanitize_sql_array([ "similarity(title, ?) DESC, published_at DESC", title ])))
      .limit(limit)
  end

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

  def assign_canonical_url
    self.canonical_url = UrlCanonicalizer.canonicalize(url)
  end

  def assign_low_signal
    self.low_signal = FeedNoiseClassifier.low_signal?(self)
  end

  def refresh_topic_tags
    relevant = previous_changes.key?("title") ||
               previous_changes.key?("description") ||
               previous_changes.key?("source_type") ||
               previous_changes.key?("id")
    return unless relevant

    ArticleTopicClassifier.apply!(self)
  end
end
