class DigestsController < ApplicationController
  include MutatingAuthentication

  before_action :authenticate_mutation!, only: :create

  def index
    @digests = NewsDigest.newest_first.limit(20)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          digests: @digests.map { |digest| DigestSerializer.as_json(digest) }
        }
      end
    end
  end

  def show
    @digest = NewsDigest.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: DigestSerializer.as_json(@digest) }
    end
  end

  def create
    period = params[:period].presence_in(NewsDigest::PERIODS) || "daily"
    digest = DigestBuilder.build!(period: period)

    respond_to do |format|
      format.json { render json: DigestSerializer.as_json(digest), status: :created }
      format.html { redirect_to digest_path(digest) }
    end
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
