class FetchRun < ApplicationRecord
  STATUSES = %w[success failure].freeze

  validates :source_key, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :articles_count, numericality: { greater_than_or_equal_to: 0 }
  validates :finished_at, presence: true
  validates :success_count, :failure_count, :empty_success_count,
            numericality: { greater_than_or_equal_to: 0 }

  scope :failed, -> { where(status: "failure") }
  scope :successful, -> { where(status: "success") }
  scope :recent, -> { order(finished_at: :desc) }

  def failure?
    status == "failure"
  end

  def empty_success?
    status == "success" && articles_count.to_i.zero?
  end

  def success_rate
    total = success_count.to_i + failure_count.to_i
    return nil if total.zero?

    (success_count.to_f / total * 100).round(1)
  end

  def self.record_outcome(source_key:, status:, articles_count: 0, duration_seconds: nil, error: nil)
    run = find_or_initialize_by(source_key: source_key)
    now = Time.current

    run.assign_attributes(
      status: status,
      articles_count: articles_count,
      duration_seconds: duration_seconds,
      error_class: error&.class&.name,
      error_message: error&.message,
      finished_at: now
    )

    if status == "success"
      run.success_count = run.success_count.to_i + 1
      run.last_success_at = now
      run.empty_success_count = run.empty_success_count.to_i + 1 if articles_count.to_i.zero?
      run.error_class = nil
      run.error_message = nil
    else
      run.failure_count = run.failure_count.to_i + 1
      run.last_failure_at = now
    end

    run.save!
    NewsFetchObservability.log_source_outcome(run)
    run
  end
end
