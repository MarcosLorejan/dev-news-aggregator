require "test_helper"

class ErrorReporting::SubscriberTest < ActiveSupport::TestCase
  setup do
    @previous_url = ENV["ERROR_WEBHOOK_URL"]
    ENV.delete("ERROR_WEBHOOK_URL")
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @subscriber = ErrorReporting::Subscriber.new
  end

  teardown do
    Rails.cache = @previous_cache
    if @previous_url
      ENV["ERROR_WEBHOOK_URL"] = @previous_url
    else
      ENV.delete("ERROR_WEBHOOK_URL")
    end
  end

  test "should log structured error payload" do
    error = StandardError.new("boom")

    assert_logs_match(/"event":"error.reported"/) do
      @subscriber.report(error, handled: true, severity: :error, context: { source_key: "hn" }, source: "news_fetch")
    end
  end

  test "should post webhook when ERROR_WEBHOOK_URL is set" do
    ENV["ERROR_WEBHOOK_URL"] = "https://example.com/hooks/errors"
    stub_request(:post, "https://example.com/hooks/errors")
      .to_return(status: 200, body: "ok")

    @subscriber.report(
      StandardError.new("API is down"),
      handled: true,
      severity: :error,
      context: { source_key: "hacker_news" },
      source: "news_fetch"
    )

    assert_requested :post, "https://example.com/hooks/errors", times: 1
  end

  test "should dedupe webhook alerts for the same source error" do
    ENV["ERROR_WEBHOOK_URL"] = "https://example.com/hooks/errors"
    stub_request(:post, "https://example.com/hooks/errors")
      .to_return(status: 200, body: "ok")

    2.times do
      @subscriber.report(
        StandardError.new("API is down"),
        handled: true,
        severity: :error,
        context: { source_key: "hacker_news" },
        source: "news_fetch"
      )
    end

    assert_requested :post, "https://example.com/hooks/errors", times: 1
  end

  test "should not raise when webhook delivery fails" do
    ENV["ERROR_WEBHOOK_URL"] = "https://example.com/hooks/errors"
    stub_request(:post, "https://example.com/hooks/errors").to_timeout

    assert_nothing_raised do
      @subscriber.report(
        StandardError.new("API is down"),
        handled: true,
        severity: :error,
        context: {},
        source: "news_fetch"
      )
    end
  end

  private

  def assert_logs_match(pattern)
    io = StringIO.new
    previous = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    yield
    assert_match pattern, io.string
  ensure
    Rails.logger = previous
  end
end
