class KeywordFilterSerializer
  def self.as_json(keyword_filter, article_count: nil)
    {
      id: keyword_filter.id,
      name: keyword_filter.name,
      slug: keyword_filter.slug,
      terms: keyword_filter.terms,
      active: keyword_filter.active,
      position: keyword_filter.position,
      article_count: article_count
    }
  end
end
