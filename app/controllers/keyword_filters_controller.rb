class KeywordFiltersController < ApplicationController
  include MutatingAuthentication

  before_action :authenticate_mutation!, only: %i[create update destroy]
  before_action :set_keyword_filter, only: %i[update destroy]

  def index
    KeywordFilter.bootstrap_defaults! if KeywordFilter.none?

    filters = KeywordFilter.ordered.to_a
    counts = Article.keyword_match_counts(filters.map(&:terms), scope: match_count_scope)

    render json: {
      keyword_filters: filters.each_with_index.map { |filter, index|
        KeywordFilterSerializer.as_json(filter, article_count: counts[index])
      }
    }
  end

  def create
    keyword_filter = KeywordFilter.new(keyword_filter_params)

    unless keyword_filter.save
      return render json: { errors: keyword_filter.errors.full_messages }, status: :unprocessable_entity
    end

    render json: KeywordFilterSerializer.as_json(keyword_filter), status: :created
  end

  def update
    unless @keyword_filter.update(keyword_filter_params)
      return render json: { errors: @keyword_filter.errors.full_messages }, status: :unprocessable_entity
    end

    render json: KeywordFilterSerializer.as_json(@keyword_filter)
  end

  def destroy
    @keyword_filter.destroy!
    head :no_content
  end

  private

  def set_keyword_filter
    @keyword_filter = KeywordFilter.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Keyword filter not found" }, status: :not_found
  end

  def keyword_filter_params
    raw = params.require(:keyword_filter)
    attributes = raw.permit(:name, :active, :position).to_h
    attributes[:terms] = terms_from(raw[:terms]) if raw.key?(:terms)
    attributes
  end

  # Accepts both ["ruby", "rails"] and "ruby, rails" so the UI and curl can use either.
  def terms_from(value)
    value.is_a?(String) ? value.split(",") : Array(value).map(&:to_s)
  end

  # Counts only what the feed can currently show: kept articles inside the retention window.
  def match_count_scope
    Article.not_dismissed.where(published_at: NewsAggregatorConfig.retention_days.days.ago..)
  end
end
