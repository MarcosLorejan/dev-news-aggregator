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
      article.save!
      Rails.logger.info "#{article.new_record? ? 'Created' : 'Updated'} article: #{article.title}"
    end
    
    article
  end
end
