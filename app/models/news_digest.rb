class NewsDigest < ApplicationRecord
  self.table_name = "news_digests"

  PERIODS = %w[daily weekly].freeze

  validates :period, inclusion: { in: PERIODS }
  validates :window_start, :window_end, :payload, presence: true
  validate :window_order

  scope :newest_first, -> { order(window_end: :desc, id: :desc) }

  private

  def window_order
    return if window_start.blank? || window_end.blank?
    return if window_end > window_start

    errors.add(:window_end, "must be after window_start")
  end
end
