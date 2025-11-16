class ReadArticlesController < ApplicationController
  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 50
    per_page = [per_page, 100].min

    @read_articles = Article.read
                           .includes(:read_article)
                           .order("read_articles.read_at DESC")
                           .limit(per_page)
                           .offset((page - 1) * per_page)
    @read_articles_by_source = @read_articles.group_by(&:source_type)
    @total_count = Article.read.count

    respond_to do |format|
      format.html
      format.json do
        render json: {
          articles: @read_articles.map { |article| read_article_json(article) },
          articles_by_source: @read_articles_by_source.transform_keys(&:to_s).transform_values { |articles| articles.map(&:id) },
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

  def create
    @article = Article.find(params[:article_id])
    @article.mark_as_read!

    respond_to do |format|
      format.html { redirect_to articles_path, notice: "Article marked as read" }
      format.json { render json: { message: "Article marked as read", read: true }, status: :ok }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to articles_path, alert: "Article not found" }
      format.json { render json: { error: "Article not found" }, status: :not_found }
    end
  end

  def destroy
    @article = Article.find(params[:article_id])

    unless @article.read?
      respond_to do |format|
        format.html { redirect_to read_articles_path, alert: "Article is not marked as read" }
        format.json { render json: { error: "Article is not marked as read" }, status: :unprocessable_entity }
      end
      return
    end

    @article.unmark_as_read!

    respond_to do |format|
      format.html { redirect_to read_articles_path, notice: "Article marked as unread" }
      format.json { render json: { message: "Article marked as unread", read: false }, status: :ok }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to read_articles_path, alert: "Article not found" }
      format.json { render json: { error: "Article not found" }, status: :not_found }
    end
  end

  private

  def read_article_json(article)
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
      read_at: article.read_article&.read_at,
      bookmarked: article.bookmarked?
    }
  end
end
