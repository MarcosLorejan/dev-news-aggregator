class SourcesController < ApplicationController
  include MutatingAuthentication

  before_action :authenticate_mutation!, only: %i[create update destroy]
  before_action :set_source, only: [ :update, :destroy ]

  def index
    NewsSource.bootstrap_defaults! if NewsSource.none?

    respond_to do |format|
      format.html
      format.json { render json: { sources: sources_json } }
    end
  end

  def update
    unless @source.update(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
      return render json: { errors: @source.errors.full_messages }, status: :unprocessable_entity
    end

    render json: source_json(@source)
  end

  def create
    source_type = params[:source_type].presence || (params[:subreddit].present? ? "reddit" : nil)

    case source_type
    when "reddit"
      create_reddit_source
    when "youtube"
      create_youtube_source
    else
      render json: { error: "source_type must be reddit or youtube" }, status: :unprocessable_entity
    end
  end

  def destroy
    unless %w[reddit youtube].include?(@source.source_type)
      return render json: { error: "Only Reddit and YouTube sources can be removed" }, status: :unprocessable_entity
    end

    @source.destroy!
    head :no_content
  end

  private

  def create_reddit_source
    subreddit = RedditSubredditValidator.normalize(params.require(:subreddit))

    if subreddit.blank?
      return render json: { error: "Subreddit name is required" }, status: :unprocessable_entity
    end

    unless RedditSubredditValidator.valid?(subreddit)
      return render json: { error: "Subreddit not found or not accessible" }, status: :unprocessable_entity
    end

    source = NewsSource.create!(
      name: subreddit,
      source_type: "reddit",
      config: { "subreddit" => subreddit },
      active: true
    )

    render json: source_json(source), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def create_youtube_source
    raw = params[:channel].presence || params[:channel_id].presence || params[:channel_url].presence
    if raw.blank?
      return render json: { error: "Channel ID, URL, or @handle is required" }, status: :unprocessable_entity
    end

    result = YoutubeChannelValidator.resolve(raw)
    unless result.valid?
      return render json: { error: result.error }, status: :unprocessable_entity
    end

    source = NewsSource.create!(
      name: result.channel_name,
      source_type: "youtube",
      config: {
        "channel_id" => result.channel_id,
        "channel_name" => result.channel_name
      },
      active: true
    )

    render json: source_json(source), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def set_source
    @source = NewsSource.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Source not found" }, status: :not_found
  end

  def sources_json
    sources = NewsSource.order(:source_type, :name).to_a
    keys = sources.map(&:source_key)
    runs_by_key = FetchRun.where(source_key: keys).index_by(&:source_key)
    last_article_at_by_key = Article.where(source_type: keys).group(:source_type).maximum(:published_at)
    sources.map { |source|
      source_json(source, runs_by_key[source.source_key], last_article_at_by_key[source.source_key])
    }
  end

  def source_json(source, fetch_run = nil, last_article_at = nil)
    fetch_run ||= FetchRun.find_by(source_key: source.source_key)
    last_article_at ||= Article.where(source_type: source.source_key).maximum(:published_at)

    {
      id: source.id,
      name: source.name,
      source_type: source.source_type,
      subreddit: source.subreddit,
      channel_id: source.channel_id,
      channel_name: source.source_type == "youtube" ? source.channel_name : nil,
      active: source.active,
      last_fetch: last_fetch_json(fetch_run, last_article_at)
    }
  end

  def last_fetch_json(fetch_run, last_article_at = nil)
    return nil unless fetch_run

    {
      status: fetch_run.status,
      finished_at: fetch_run.finished_at,
      articles_count: fetch_run.articles_count,
      duration_seconds: fetch_run.duration_seconds,
      error_class: fetch_run.error_class,
      error_message: fetch_run.error_message,
      empty: fetch_run.empty_success?,
      success_count: fetch_run.success_count,
      failure_count: fetch_run.failure_count,
      empty_success_count: fetch_run.empty_success_count,
      success_rate: fetch_run.success_rate,
      last_success_at: fetch_run.last_success_at,
      last_failure_at: fetch_run.last_failure_at,
      last_article_at: last_article_at
    }
  end
end
