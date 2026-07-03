require "test_helper"

class NewsFetchObservabilityTest < ActiveSupport::TestCase
  test "log_source_outcome emits structured json for success" do
    run = FetchRun.create!(
      source_key: "hacker_news",
      status: "success",
      articles_count: 3,
      duration_seconds: 1.1,
      finished_at: Time.current
    )

    io = StringIO.new
    with_logger(io) do
      NewsFetchObservability.log_source_outcome(run)
    end

    payload = JSON.parse(io.string.lines.last)
    assert_equal "news_fetch.source_completed", payload["event"]
    assert_equal "hacker_news", payload["source"]
    assert_equal "success", payload["status"]
    assert_equal 3, payload["articles_count"]
  end

  test "log_source_outcome emits structured json for failure" do
    run = FetchRun.create!(
      source_key: "dev_to",
      status: "failure",
      articles_count: 0,
      duration_seconds: 0.5,
      error_class: "Net::ReadTimeout",
      error_message: "execution expired",
      finished_at: Time.current
    )

    io = StringIO.new
    with_logger(io) do
      NewsFetchObservability.log_source_outcome(run)
    end

    payload = JSON.parse(io.string.lines.last)
    assert_equal "failure", payload["status"]
    assert_equal "Net::ReadTimeout", payload["error_class"]
  end

  private

  def with_logger(io)
    original = Rails.logger
    Rails.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(io))
    yield
  ensure
    Rails.logger = original
  end
end
