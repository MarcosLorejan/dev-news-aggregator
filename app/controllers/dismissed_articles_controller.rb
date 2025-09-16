class DismissedArticlesController < ApplicationController
  def index
    @dismissed_articles = Article.dismissed.order("dismissed_articles.dismissed_at DESC").limit(100)
  end

  def recently_dismissed
    @articles = Article.joins(:dismissed_article)
                      .where("dismissed_articles.dismissed_at > ?", 24.hours.ago)
                      .order("dismissed_articles.dismissed_at DESC")
                      .limit(10)
  end
end
