class Article < ApplicationRecord
  has_one :bookmark, dependent: :destroy
  has_one :read_article, dependent: :destroy
  has_one :dismissed_article, dependent: :destroy

  scope :bookmarked, -> { joins(:bookmark) }
  scope :not_bookmarked, -> { left_joins(:bookmark).where(bookmarks: { id: nil }) }
  scope :read, -> { joins(:read_article) }
  scope :not_read, -> { left_joins(:read_article).where(read_articles: { id: nil }) }
  scope :not_dismissed, -> { left_joins(:dismissed_article).where('dismissed_articles.id IS NULL OR dismissed_articles.permanent = false') }
  scope :dismissed, -> { joins(:dismissed_article).where(dismissed_articles: { permanent: true }) }
  scope :pending_dismissal, -> { joins(:dismissed_article).where(dismissed_articles: { permanent: false }) }

  def bookmarked?
    bookmark.present?
  end

  def bookmark!
    return bookmark if bookmarked?
    create_bookmark
  end

  def unbookmark!
    if bookmark
      bookmark.destroy
      reload
    end
  end

  def toggle_bookmark!
    return unbookmark! if bookmarked?
    bookmark!
  end

  def read?
    read_article.present?
  end

  def mark_as_read!
    return read_article if read?
    create_read_article
  end

  def unmark_as_read!
    if read_article
      read_article.destroy
      reload
    end
  end

  def toggle_read!
    return unmark_as_read! if read?
    mark_as_read!
  end

  def dismissed?
    dismissed_article&.permanent?
  end

  def pending_dismissal?
    dismissed_article.present? && !dismissed_article.permanent?
  end

  def dismiss!
    return dismissed_article if dismissed?
    create_dismissed_article(dismissed_at: Time.current, permanent: false)
  end

  def undismiss!
    if dismissed_article
      dismissed_article.destroy
      reload
    end
  end
end
