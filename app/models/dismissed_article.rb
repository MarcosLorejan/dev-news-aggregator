class DismissedArticle < ApplicationRecord
  belongs_to :article

  validates :article_id, uniqueness: true
  validates :dismissed_at, presence: true

  scope :temporary, -> { where(permanent: false) }
  scope :permanent, -> { where(permanent: true) }
end
