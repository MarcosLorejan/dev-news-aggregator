class ArticleSerializer
  BASE_ATTRIBUTES = %i[
    id title url description source_type score comment_count external_id published_at
  ].freeze

  def self.as_json(article)
    base_attributes(article).merge(
      created_at: article.created_at,
      updated_at: article.updated_at,
      bookmarked: article.bookmarked?,
      read: article.read?,
      dismissed: article.dismissed?,
      pending_dismissal: article.pending_dismissal?
    )
  end

  def self.as_bookmark_json(article)
    base_attributes(article).merge(
      bookmarked_at: article.bookmark&.bookmarked_at,
      read: article.read?
    )
  end

  def self.as_read_json(article)
    base_attributes(article).merge(
      read_at: article.read_article&.read_at,
      bookmarked: article.bookmarked?
    )
  end

  def self.as_dismissed_json(article)
    base_attributes(article).merge(
      dismissed_at: article.dismissed_article&.dismissed_at,
      permanent: article.dismissed_article&.permanent
    )
  end

  def self.base_attributes(article)
    BASE_ATTRIBUTES.index_with { |attribute| article.public_send(attribute) }
  end
  private_class_method :base_attributes
end
