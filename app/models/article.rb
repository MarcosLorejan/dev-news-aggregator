class Article < ApplicationRecord
  has_one :bookmark, dependent: :destroy
  has_one :read_article, dependent: :destroy

  scope :bookmarked, -> { joins(:bookmark) }
  scope :not_bookmarked, -> { left_joins(:bookmark).where(bookmarks: { id: nil }) }
  scope :read, -> { joins(:read_article) }
  scope :not_read, -> { left_joins(:read_article).where(read_articles: { id: nil }) }

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
    bookmarked? ? unbookmark! : bookmark!
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
    read? ? unmark_as_read! : mark_as_read!
  end
end
