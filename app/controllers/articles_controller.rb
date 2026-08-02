class ArticlesController < ApplicationController
  include Pagination
  include MutatingAuthentication

  FETCH_RATE_LIMIT = 2.minutes

  ALLOWED_SORTS = {
    "published_at" => Arel.sql("low_signal ASC, published_at DESC"),
    "score" => Arel.sql("low_signal ASC, score DESC NULLS LAST, published_at DESC"),
    "comment_count" => Arel.sql("low_signal ASC, comment_count DESC NULLS LAST, published_at DESC"),
    "for_you" => :for_you
  }.freeze

  before_action :authenticate_mutation!, only: %i[fetch bookmark unbookmark dismiss undismiss summarize]

  def index
    @show_read = params[:show_read] == "true"
    page, per_page = pagination_params

    count_scope = article_index_scope(apply_category: false)
    @category_counts = helpers.category_counts_for_scope(count_scope)

    base_scope = article_index_scope
    @total_count = base_scope.unscope(:includes, :order, :select).count
    @articles = base_scope.limit(per_page).offset((page - 1) * per_page)
    @topic_tags = Tag.order(:name).map { |tag| { slug: tag.slug, name: tag.name } }
    @related_by_article_id = ArticleClusterer.related_by_article_id(@articles)

    @articles_by_source = @articles.group_by(&:source_type)
    @articles_by_category = helpers.group_sources_by_category(@articles_by_source)
    @last_updated = Article.maximum(:updated_at)
    filter_terms = active_keyword_terms

    respond_to do |format|
      format.html
      format.json do
        render json: {
          articles: @articles.map { |article|
            ArticleSerializer.as_json(
              article,
              related_articles: @related_by_article_id[article.id] || [],
              matched_keywords: filter_terms && article.matched_keywords_for(filter_terms)
            )
          },
          articles_by_category: @articles_by_category.transform_values { |articles| articles.map(&:id) },
          category_counts: @category_counts,
          categories: @category_counts.keys.map { |name| { name: name, icon: helpers.category_icon(name) } },
          topic_tags: @topic_tags,
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: @total_count,
            total_pages: (@total_count.to_f / per_page).ceil
          },
          last_updated: @last_updated
        }
      end
      format.atom
    end
  end

  def fetch
    if fetch_rate_limited?
      return render json: { error: "Please wait before fetching again" }, status: :too_many_requests
    end

    job = FetchNewsJob.perform_later

    render json: {
      status: "queued",
      job_id: job.job_id
    }, status: :accepted
  end

  def show
    @article = Article.includes(:bookmark, :read_article, :dismissed_article).find(params[:id])
    @similar_articles = Article.similar_to(@article).includes(:bookmark, :read_article, :dismissed_article)

    respond_to do |format|
      format.html
      format.json {
        render json: ArticleSerializer.as_json(@article, include_summary: true).merge(
          similar_articles: @similar_articles.map { |article| ArticleSerializer.as_json(article) }
        )
      }
    end
  end

  def summarize
    @article = Article.find(params[:id])
    result = ArticleSummarizer.call(@article, force: ActiveModel::Type::Boolean.new.cast(params[:force]))

    render json: {
      summary: result.summary,
      summary_provider: result.provider,
      summarized_at: @article.reload.summarized_at,
      summarizer: ArticleSummarizer.config,
      error: result.error
    }
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

  def article_index_scope(apply_category: true)
    scope = if @show_read
              Article.not_dismissed
    else
              Article.not_read.not_dismissed
    end

    scope = apply_score_filter(scope)
    scope = scope.search(params[:q])
    scope = apply_keyword_filter(scope)
    scope = scope.with_topic_tag(params[:tag])
    scope = helpers.apply_category_filter(scope, params[:category]) if apply_category
    scope = ArticleClusterer.primaries(scope)
    apply_sort(scope.includes(:bookmark, :read_article, :dismissed_article, :tags))
  end

  # `interests=<slug,slug>` (or singular `interest`) expands to the presets' saved terms, unioned
  # with any explicit `keywords`; `match` then applies to the combined list. An unknown slug
  # filters everything out, mirroring how an unknown category behaves.
  def apply_keyword_filter(scope)
    terms = resolved_keyword_terms
    return scope.none if terms == :unknown

    scope.matching_keywords(terms, match: params[:match])
  end

  # Normalized terms currently driving the keyword/interest filter, or nil when none apply.
  def active_keyword_terms
    terms = resolved_keyword_terms
    return nil if terms == :unknown || terms.empty?

    terms
  end

  def resolved_keyword_terms
    terms = Article.normalize_keywords(params[:keywords])
    slugs = interest_slugs
    return terms if slugs.empty?

    interests = KeywordFilter.where(slug: slugs).to_a
    return :unknown if interests.size < slugs.size

    Article.normalize_keywords(terms + interests.flat_map(&:terms))
  end

  def interest_slugs
    [ params[:interests], params[:interest] ]
      .flat_map { |value| value.to_s.split(",") }
      .map { |slug| slug.strip.downcase }
      .reject(&:empty?)
      .uniq
  end

  def apply_sort(scope)
    if params[:q].present? && params[:sort].blank?
      q = params[:q].to_s.strip
      return scope.order(
        Arel.sql(
          Article.sanitize_sql_array(
            [
              "GREATEST(similarity(articles.title, ?), similarity(COALESCE(articles.description, ''), ?)) DESC, articles.published_at DESC",
              q,
              q
            ]
          )
        )
      )
    end

    key = params[:sort].presence_in(ALLOWED_SORTS.keys) || "published_at"
    return PersonalFeedRanker.apply(scope) if key == "for_you"

    scope.order(ALLOWED_SORTS[key])
  end

  def apply_score_filter(scope)
    if params[:min_score].present?
      scope.where("score >= ?", params[:min_score].to_i)
    elsif params[:top_percent].present?
      percent = params[:top_percent].to_i.clamp(1, 100)
      scored = scope.where.not(score: nil)
      count = scored.count
      return scope if count.zero?

      # Same discrete threshold as former pluck + index: top N scores by OFFSET.
      index = [ (count * percent / 100.0).ceil - 1, 0 ].max
      threshold = scored.order(score: :desc).offset(index).limit(1).pick(:score)
      scope.where("score >= ?", threshold)
    else
      scope
    end
  end

  def fetch_rate_limited?
    key = "articles_fetch:#{request.remote_ip}"
    # Atomic claim: only the first writer in the window proceeds.
    !Rails.cache.write(key, Time.current, expires_in: FETCH_RATE_LIMIT, unless_exist: true)
  end
end
