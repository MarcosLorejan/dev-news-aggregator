class DismissedArticlesController < ApplicationController
  include Pagination

  def index
    page, per_page = pagination_params

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
          articles: @dismissed_articles.map { |article| ArticleSerializer.as_dismissed_json(article) },
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
          articles: @articles.map { |article| ArticleSerializer.as_dismissed_json(article) }
        }
      end
    end
  end
end
