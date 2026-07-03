class FetchRun < ApplicationRecord
  STATUSES = %w[success failure].freeze

  validates :source_key, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :articles_count, numericality: { greater_than_or_equal_to: 0 }
  validates :finished_at, presence: true

  scope :failed, -> { where(status: "failure") }
  scope :successful, -> { where(status: "success") }
  scope :recent, -> { order(finished_at: :desc) }

  def failure?
    status == "failure"
  end

  def self.record_outcome(source_key:, status:, articles_count: 0, duration_seconds: nil, error: nil)
    run = find_or_initialize_by(source_key: source_key)
    run.assign_attributes(
      status: status,
      articles_count: articles_count,
      duration_seconds: duration_seconds,
      error_class: error&.class&.name,
      error_message: error&.message,
      finished_at: Time.current
    )
    run.save!
    NewsFetchObservability.log_source_outcome(run)
    run
  end
end
