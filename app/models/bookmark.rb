class Bookmark < ApplicationRecord
  belongs_to :article

  validates :article_id, presence: true, uniqueness: true

  before_create :set_bookmarked_at

  scope :recent, -> { order(bookmarked_at: :desc) }

  private

  def set_bookmarked_at
    self.bookmarked_at ||= Time.current
  end
end
