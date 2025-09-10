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
      format.html { redirect_back(fallback_location: articles_path) }
      format.json { head :ok }
    end
  end

  def destroy
    @article = Article.find(params[:article_id])
    @article.unmark_as_read!
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: articles_path) }
      format.json { head :ok }
    end
  end
end
