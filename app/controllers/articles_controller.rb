class ArticlesController < ApplicationController
  FETCH_RATE_LIMIT = 2.minutes

  def index
    @show_read = params[:show_read] == "true"
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 50
    per_page = [ per_page, 100 ].min

    base_scope = article_index_scope
    @total_count = base_scope.count
    @articles = base_scope.limit(per_page).offset((page - 1) * per_page)

    @articles_by_source = @articles.group_by(&:source_type)
    @articles_by_category = helpers.group_sources_by_category(@articles_by_source)
    @last_updated = Article.maximum(:updated_at)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          articles: @articles.map { |article| article_json(article) },
          articles_by_category: @articles_by_category.transform_values { |articles| articles.map(&:id) },
          categories: @articles_by_category.keys.map { |name| { name: name, icon: helpers.category_icon(name) } },
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

  def fetch
    if fetch_rate_limited?
      return render json: { error: "Please wait before fetching again" }, status: :too_many_requests
    end

    result = NewsAggregatorService.fetch_all_news

    render json: {
      articles_count: result[:articles_count],
      duration: result[:duration],
      sources: result[:sources],
      timestamp: result[:timestamp]
    }
  end

  def show
    @article = Article.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: article_json(@article) }
    end
  end

  def bookmark
    @article = Article.find(params[:id])
    @article.bookmark!

    respond_to do |format|
      format.html { redirect_back(fallback_location: articles_path) }
      format.json { render json: { bookmarked: @article.bookmarked? } }
    end
  end

  def unbookmark
    @article = Article.find(params[:id])
    @article.unbookmark!

    respond_to do |format|
      format.html { redirect_back(fallback_location: articles_path) }
      format.json { render json: { bookmarked: @article.bookmarked? } }
    end
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
  end

  def undismiss
    @article = Article.find(params[:id])
    @article.undismiss!

    respond_to do |format|
      format.json { render json: { status: "restored" } }
      format.html { redirect_back(fallback_location: articles_path) }
    end
  end

  private

  def article_index_scope
    scope = if @show_read
              Article.not_dismissed
    else
              Article.not_read.not_dismissed
    end

    scope = apply_score_filter(scope)
    scope.order(published_at: :desc)
  end

  def apply_score_filter(scope)
    if params[:min_score].present?
      scope.where("score >= ?", params[:min_score].to_i)
    elsif params[:top_percent].present?
      percent = params[:top_percent].to_i.clamp(1, 100)
      scores = scope.where.not(score: nil).order(score: :desc).pluck(:score)
      return scope if scores.empty?

      index = [ (scores.size * percent / 100.0).ceil - 1, 0 ].max
      scope.where("score >= ?", scores[index])
    else
      scope
    end
  end

  def fetch_rate_limited?
    key = "articles_fetch:#{request.remote_ip}"
    last_fetch = Rails.cache.read(key)
    return true if last_fetch && last_fetch > FETCH_RATE_LIMIT.ago

    Rails.cache.write(key, Time.current, expires_in: FETCH_RATE_LIMIT)
    false
  end

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
end
