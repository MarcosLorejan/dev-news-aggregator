class NewsFetchers::DevToFetcher < NewsFetchers::BaseFetcher
  base_uri 'https://dev.to/api'

  def fetch_articles
    Rails.logger.info "Fetching articles from Dev.to..."
    
    # Get latest articles
    articles_data = self.class.get('/articles', query: { per_page: 30, top: 7 })
    return [] unless articles_data.is_a?(Array)

    articles_data.each do |article_data|
      create_article_from_data(article_data)
    end

    Rails.logger.info "Fetched #{@articles.length} articles from Dev.to"
    @articles
  end

  private

  def create_article_from_data(article_data)
    article_attributes = {
      title: article_data['title'],
      url: article_data['url'],
      published_at: DateTime.parse(article_data['published_at']),
      description: article_data['description'] || '',
      external_id: article_data['id'].to_s,
      source_type: 'dev_to',
      score: article_data['positive_reactions_count'] || 0,
      comment_count: article_data['comments_count'] || 0
    }

    article = create_or_update_article(article_attributes)
    @articles << article if article.persisted?
  rescue StandardError => e
    Rails.logger.error "Error creating Dev.to article #{article_data['id']}: #{e.message}"
  end
end
