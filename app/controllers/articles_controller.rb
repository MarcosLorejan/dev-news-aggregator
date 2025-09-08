class ArticlesController < ApplicationController
  def index
    @articles = Article.order(published_at: :desc)
                      .limit(50)
    @articles_by_source = @articles.group_by(&:source_type)
    @total_count = Article.count
    @last_updated = Article.maximum(:updated_at)
  end

  def show
    @article = Article.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: "Article not found."
  end
end
