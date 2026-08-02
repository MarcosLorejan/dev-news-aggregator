require "test_helper"

class FetchRunTest < ActiveSupport::TestCase
  test "record_outcome upserts latest success per source" do
    FetchRun.record_outcome(
      source_key: "hacker_news",
      status: "success",
      articles_count: 5,
      duration_seconds: 1.2
    )

    assert_difference "FetchRun.count", 0 do
      run = FetchRun.record_outcome(
        source_key: "hacker_news",
        status: "success",
        articles_count: 8,
        duration_seconds: 0.9
      )

      assert_equal 8, run.articles_count
      assert_equal "success", run.status
    end
  end

  test "record_outcome stores failure details" do
    error = StandardError.new("API down")
    run = FetchRun.record_outcome(
      source_key: "dev_to",
      status: "failure",
      duration_seconds: 2.5,
      error: error
    )

    assert run.failure?
    assert_equal "StandardError", run.error_class
    assert_equal "API down", run.error_message
    assert_equal 1, run.failure_count
    assert_not_nil run.last_failure_at
  end

  test "record_outcome increments health counters and empty successes" do
    FetchRun.record_outcome(source_key: "hacker_news", status: "success", articles_count: 0)
    run = FetchRun.record_outcome(source_key: "hacker_news", status: "success", articles_count: 3)
    FetchRun.record_outcome(source_key: "hacker_news", status: "failure", error: StandardError.new("boom"))

    run.reload
    assert_equal 2, run.success_count
    assert_equal 1, run.failure_count
    assert_equal 1, run.empty_success_count
    assert_equal 66.7, run.success_rate
  end

  test "failed scope returns only failed sources" do
    FetchRun.record_outcome(source_key: "hacker_news", status: "success", articles_count: 1)
    FetchRun.record_outcome(
      source_key: "reddit_rust",
      status: "failure",
      error: StandardError.new("timeout")
    )

    assert_equal [ "reddit_rust" ], FetchRun.failed.pluck(:source_key)
  end
end
