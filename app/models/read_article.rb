class ReadArticle < ApplicationRecord
  belongs_to :article

  validates :article_id, presence: true, uniqueness: true

  before_create :set_read_at

  scope :recent, -> { order(read_at: :desc) }

  private

  def set_read_at
    self.read_at ||= Time.current
  end
end
