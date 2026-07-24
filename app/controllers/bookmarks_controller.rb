class BookmarksController < ApplicationController
  include Pagination

  def index
    page, per_page = pagination_params

    @bookmarked_articles = Article.bookmarked
                                 .includes(:bookmark)
                                 .order("bookmarks.bookmarked_at DESC")
                                 .limit(per_page)
                                 .offset((page - 1) * per_page)
    @bookmarks_by_source = @bookmarked_articles.group_by(&:source_type)
    @total_count = Article.bookmarked.count

    respond_to do |format|
      format.html
      format.json do
        render json: {
          articles: @bookmarked_articles.map { |article| ArticleSerializer.as_bookmark_json(article) },
          articles_by_source: @bookmarks_by_source.transform_keys(&:to_s).transform_values { |articles| articles.map(&:id) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: @total_count,
            total_pages: (@total_count.to_f / per_page).ceil
          }
        }
      end
      format.atom
    end
  end
end
