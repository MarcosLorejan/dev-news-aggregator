class MakeDismissalPermanentJob < ApplicationJob
  queue_as :default

  def perform(dismissed_article_id)
    dismissed = DismissedArticle.find_by(id: dismissed_article_id)
    dismissed&.update(permanent: true) if dismissed&.permanent == false
  end
end
