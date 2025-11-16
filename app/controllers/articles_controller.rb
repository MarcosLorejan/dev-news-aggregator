class ArticlesController < ApplicationController
  def index
    @show_read = params[:show_read] == "true"
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 50
    per_page = [per_page, 100].min

    @articles = if @show_read
                  Article.not_dismissed.order(published_at: :desc)
    else
                  Article.not_read.not_dismissed.order(published_at: :desc)
    end.limit(per_page).offset((page - 1) * per_page)

    @articles_by_source = @articles.group_by(&:source_type)
    @articles_by_category = group_sources_by_category(@articles_by_source)
    @total_count = if @show_read
                     Article.not_dismissed.count
    else
                     Article.not_read.not_dismissed.count
    end
    @last_updated = Article.maximum(:updated_at)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          articles: @articles.map { |article| article_json(article) },
          articles_by_category: @articles_by_category.transform_values { |articles| articles.map(&:id) },
          categories: @articles_by_category.keys.map { |name| { name: name, icon: category_icon(name) } },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: @total_count,
            total_pages: (@total_count.to_f / per_page).ceil
          },
          last_updated: @last_updated
        }
      end
    end
  end

  def show
    @article = Article.find(params[:id])
    
    respond_to do |format|
      format.html
      format.json { render json: article_json(@article) }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to articles_path, alert: "Article not found." }
      format.json { render json: { error: "Article not found" }, status: :not_found }
    end
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

    MakeDismissalPermanentJob.set(wait: 15.seconds).perform_later(dismissed.id)

    respond_to do |format|
      format.turbo_stream
      format.json { render json: { status: "dismissed", timeout: 15 } }
      format.html { redirect_back(fallback_location: articles_path) }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: "Article not found."
  end

  def undismiss
    @article = Article.find(params[:id])
    @article.undismiss!

    respond_to do |format|
      format.json { render json: { status: "restored" } }
      format.html { redirect_back(fallback_location: articles_path) }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to articles_path, alert: "Article not found." }
      format.json { render json: { error: "Article not found" }, status: :not_found }
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
      created_at: article.created_at,
      updated_at: article.updated_at,
      bookmarked: article.bookmarked?,
      read: article.read?,
      dismissed: article.dismissed?,
      pending_dismissal: article.pending_dismissal?
    }
  end

  def group_sources_by_category(articles_by_source)
    categories = {
      "Programming Languages" => %w[reddit_ruby reddit_rust reddit_javascript],
      "Web Development" => %w[reddit_webdev reddit_programming],
      "Security" => %w[reddit_netsec reddit_cybersecurity],
      "AI & Machine Learning" => %w[reddit_MachineLearning reddit_artificial reddit_LocalLLaMA],
      "General Tech" => %w[hacker_news dev_to reddit_technology]
    }

    grouped = {}

    categories.each do |category_name, source_types|
      category_articles = []
      source_types.each do |source_type|
        category_articles.concat(articles_by_source[source_type] || [])
      end
      grouped[category_name] = category_articles if category_articles.any?
    end

    other_sources = articles_by_source.keys - categories.values.flatten
    if other_sources.any?
      other_articles = []
      other_sources.each do |source_type|
        other_articles.concat(articles_by_source[source_type])
      end
      grouped["Other"] = other_articles if other_articles.any?
    end

    grouped
  end

  def category_icon(category_name)
    icons = {
      "Programming Languages" => "🔨",
      "Web Development" => "🌐",
      "Security" => "🔒",
      "AI & Machine Learning" => "🤖",
      "General Tech" => "💻",
      "Other" => "📰"
    }
    icons[category_name] || "📄"
  end
end
