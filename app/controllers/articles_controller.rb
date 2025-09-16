class ArticlesController < ApplicationController
  def index
    @show_read = params[:show_read] == "true"

    @articles = if @show_read
                  Article.not_dismissed.order(published_at: :desc)
    else
                  Article.not_read.not_dismissed.order(published_at: :desc)
    end.limit(50)

    @articles_by_source = @articles.group_by(&:source_type)
    @articles_by_category = view_context.group_sources_by_category(@articles_by_source)
    @total_count = if @show_read
                     Article.not_dismissed.count
    else
                     Article.not_read.not_dismissed.count
    end
    @last_updated = Article.maximum(:updated_at)
  end

  def show
    @article = Article.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: "Article not found."
  end

  def bookmark
    @article = Article.find(params[:id])
    @article.bookmark!

    respond_to do |format|
      format.html { redirect_back(fallback_location: articles_path) }
      format.json { render json: { bookmarked: @article.bookmarked? } }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: "Article not found."
  end

  def unbookmark
    @article = Article.find(params[:id])
    @article.unbookmark!

    respond_to do |format|
      format.html { redirect_back(fallback_location: articles_path) }
      format.json { render json: { bookmarked: @article.bookmarked? } }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: "Article not found."
  end

  def dismiss
    @article = Article.find(params[:id])
    dismissed = @article.dismiss!

    MakeDismissalPermanentJob.perform_in(15.seconds, dismissed.id)

    respond_to do |format|
      format.turbo_stream
      format.json { render json: { status: 'dismissed', timeout: 15 } }
      format.html { redirect_back(fallback_location: articles_path) }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: "Article not found."
  end

  def undismiss
    @article = Article.find(params[:id])
    @article.undismiss!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@article, @article) }
      format.json { render json: { status: 'restored' } }
      format.html { redirect_back(fallback_location: articles_path) }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: "Article not found."
  end
end
