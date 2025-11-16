class DismissedArticlesController < ApplicationController
  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 50
    per_page = [per_page, 100].min

    @dismissed_articles = Article.dismissed
                                .includes(:dismissed_article)
                                .order("dismissed_articles.dismissed_at DESC")
                                .limit(per_page)
                                .offset((page - 1) * per_page)
    @total_count = Article.dismissed.count

    respond_to do |format|
      format.html
      format.json do
        render json: {
          articles: @dismissed_articles.map { |article| article_json(article) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: @total_count,
            total_pages: (@total_count.to_f / per_page).ceil
          }
        }
      end
    end
  end

  def recently_dismissed
    @articles = Article.joins(:dismissed_article)
                      .includes(:dismissed_article)
                      .where("dismissed_articles.dismissed_at > ?", 24.hours.ago)
                      .order("dismissed_articles.dismissed_at DESC")
                      .limit(10)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          articles: @articles.map { |article| article_json(article) }
        }
      end
    end
  end

  private

  def article_json(article)
    {
      id: article.id,
      title: article.title,
      url: article.url,
      description: article.description,
      source_type: article.source_type,
      score: article.score,
      comment_count: article.comment_count,
      external_id: article.external_id,
      published_at: article.published_at,
      dismissed_at: article.dismissed_article&.dismissed_at,
      permanent: article.dismissed_article&.permanent
    }
  end
end
