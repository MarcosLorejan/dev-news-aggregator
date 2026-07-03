class BookmarksController < ApplicationController
  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 50
    per_page = [ per_page, 100 ].min

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
          articles: @bookmarked_articles.map { |article| article_json(article) },
          articles_by_source: @bookmarks_by_source.transform_keys(&:to_s).transform_values { |articles| articles.map(&:id) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: @total_count,
            total_pages: (@total_count.to_f / per_page).ceil
          }
        }
      end
    end
  end

  private

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
      bookmarked_at: article.bookmark&.bookmarked_at,
      read: article.read?
    }
  end
end
