class BookmarksController < ApplicationController
  def index
    @bookmarked_articles = Article.bookmarked
                                 .includes(:bookmark)
                                 .order("bookmarks.bookmarked_at DESC")
    @bookmarks_by_source = @bookmarked_articles.group_by(&:source_type)
  end
end
