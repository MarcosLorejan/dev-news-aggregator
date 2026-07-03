class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found
    respond_to do |format|
      format.html { redirect_back(fallback_location: articles_path, alert: "Article not found.") }
      format.json { render json: { error: "Article not found" }, status: :not_found }
    end
  end
end
