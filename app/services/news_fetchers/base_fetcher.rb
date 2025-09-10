class NewsFetchers::BaseFetcher
  include HTTParty

  def initialize
    @articles = []
  end

  def fetch_articles
    raise NotImplementedError, "Subclasses must implement fetch_articles method"
  end

  protected

  def create_or_update_article(attributes)
    article = Article.find_or_initialize_by(
      external_id: attributes[:external_id],
      source_type: attributes[:source_type]
    )

    article.assign_attributes(attributes)

    if article.new_record? || article.changed?
      is_new_record = article.new_record?
      article.save!
      if is_new_record
        Rails.logger.info "Created article: #{article.title}"
      else
        Rails.logger.info "Updated article: #{article.title}"
      end
    end

    article
  end
end
