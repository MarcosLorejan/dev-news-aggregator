class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique

  private

  def record_not_found
    respond_to do |format|
      format.html { redirect_back(fallback_location: articles_path, alert: "Article not found.") }
      format.json { render json: { error: "Article not found" }, status: :not_found }
    end
  end

  # Concurrent bookmark/read/dismiss can lose the insert race; treat as idempotent success.
  def record_not_unique
    @article&.reload

    respond_to do |format|
      format.html { redirect_back(fallback_location: articles_path) }
      format.turbo_stream { head :ok }
      format.json { render json: idempotent_mutation_json, status: :ok }
    end
  end

  def idempotent_mutation_json
    case action_name
    when "bookmark"
      { bookmarked: @article.nil? || @article.bookmarked? }
    when "dismiss"
      { status: "dismissed", timeout: 15 }
    when "create"
      { message: "Article marked as read", read: true }
    else
      { ok: true }
    end
  end
end
