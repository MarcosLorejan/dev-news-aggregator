class SourcesController < ApplicationController
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

  def destroy
    unless @source.source_type == "reddit"
      return render json: { error: "Only Reddit sources can be removed" }, status: :unprocessable_entity
    end

    @source.destroy!
    head :no_content
  end

  private

  def set_source
    @source = NewsSource.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Source not found" }, status: :not_found
  end

  def sources_json
    NewsSource.order(:source_type, :name).map { |source| source_json(source) }
  end

  def source_json(source)
    {
      id: source.id,
      name: source.name,
      source_type: source.source_type,
      subreddit: source.subreddit,
      active: source.active
    }
  end
end
