class ReadArticlesController < ApplicationController
  def index
    @read_articles = Article.read
                           .includes(:read_article)
                           .order("read_articles.read_at DESC")
    @read_articles_by_source = @read_articles.group_by(&:source_type)
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
