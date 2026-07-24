class ReadArticlesController < ApplicationController
  include Pagination
  include MutatingAuthentication

  before_action :authenticate_mutation!, only: %i[create destroy]

  def index
    page, per_page = pagination_params

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
          articles: @read_articles.map { |article| ArticleSerializer.as_read_json(article) },
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
end
