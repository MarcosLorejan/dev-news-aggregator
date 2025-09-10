class Article < ApplicationRecord
  has_one :bookmark, dependent: :destroy

  scope :bookmarked, -> { joins(:bookmark) }
  scope :not_bookmarked, -> { left_joins(:bookmark).where(bookmarks: { id: nil }) }

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
end
