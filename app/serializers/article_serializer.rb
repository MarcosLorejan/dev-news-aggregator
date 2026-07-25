class ArticleSerializer
  BASE_ATTRIBUTES = %i[
    id title url description source_type score comment_count external_id published_at
  ].freeze

  def self.as_json(article, related_articles: [])
    base_attributes(article).merge(
      created_at: article.created_at,
      updated_at: article.updated_at,
      bookmarked: article.bookmarked?,
      read: article.read?,
      dismissed: article.dismissed?,
      pending_dismissal: article.pending_dismissal?,
      related_sources: Array(related_articles).map { |related| related_source_json(related) }
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

  def self.related_source_json(article)
    {
      id: article.id,
      source_type: article.source_type,
      url: article.url,
      title: article.title,
      score: article.score
    }
  end
  private_class_method :related_source_json
end
