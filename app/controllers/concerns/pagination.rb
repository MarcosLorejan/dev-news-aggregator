module Pagination
  extend ActiveSupport::Concern

  private

  def pagination_params(default_per_page: 50, max_per_page: 100)
    page = params[:page].presence&.to_i || 1
    page = 1 if page < 1

    per_page = params[:per_page].presence&.to_i || default_per_page
    per_page = per_page.clamp(1, max_per_page)

    [ page, per_page ]
  end
end
