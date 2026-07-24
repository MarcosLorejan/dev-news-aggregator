require "test_helper"

class NewsAggregatorServiceTest < ActiveSupport::TestCase
  def setup
    @service = NewsAggregatorService.new
  end

  test "should initialize with multiple fetchers" do
    fetchers = @service.instance_variable_get(:@fetchers)

    assert fetchers.length >= 2
    assert fetchers.any? { |f| f.is_a?(NewsFetchers::HackerNewsFetcher) }
    assert fetchers.any? { |f| f.is_a?(NewsFetchers::DevToFetcher) }
    assert fetchers.any? { |f| f.is_a?(NewsFetchers::RedditFetcher) }
  end

  test "builds default fetchers from news aggregator config when database sources are absent" do
    NewsSource.delete_all

    fetchers = NewsAggregatorService.build_fetchers

    assert fetchers.any? { |f| f.is_a?(NewsFetchers::HackerNewsFetcher) }
    assert fetchers.any? { |f| f.is_a?(NewsFetchers::DevToFetcher) }
    reddit_fetchers = fetchers.select { |f| f.is_a?(NewsFetchers::RedditFetcher) }
    assert_equal NewsAggregatorConfig.reddit_subreddits.length, reddit_fetchers.length
  end

  test "uses enabled database sources when present" do
    NewsSource.update_all(active: false)
    news_sources(:hacker_news).update!(active: true)
    news_sources(:reddit_rust).update!(active: true)

    service = NewsAggregatorService.new
    fetchers = service.instance_variable_get(:@fetchers)

    assert_equal 2, fetchers.length
    assert fetchers.any? { |f| f.is_a?(NewsFetchers::HackerNewsFetcher) }
    assert fetchers.one? { |f| f.is_a?(NewsFetchers::RedditFetcher) }
  end

  test "should initialize with empty articles array" do
    all_articles = @service.instance_variable_get(:@all_articles)
    assert_equal [], all_articles
  end

  test "fetch_all_news should handle fetcher failures gracefully" do
    # Mock a fetcher that raises an error
    failing_fetcher = Object.new
    def failing_fetcher.fetch_articles
      raise StandardError, "API is down"
    end
    def failing_fetcher.source_key
      "test_failing_fetcher"
    end

    def failing_fetcher.class
      @class ||= Class.new do
        def self.name
          "TestFailingFetcher"
        end
      end
    end

    # Mock a successful fetcher
    successful_fetcher = Object.new
    def successful_fetcher.fetch_articles
      [ Article.new(title: "Test", source_type: "test") ]
    end
    def successful_fetcher.source_key
      "test_successful_fetcher"
    end

    def successful_fetcher.class
      @class ||= Class.new do
        def self.name
          "TestSuccessfulFetcher"
        end
      end
    end

    # Replace fetchers with our test ones
    @service.instance_variable_set(:@fetchers, [ failing_fetcher, successful_fetcher ])

    result = nil
    assert_nothing_raised do
      result = @service.fetch_all_news
    end

    assert_kind_of Hash, result
    assert result.key?(:articles_count)
    assert result.key?(:duration)
    assert result.key?(:sources)
    assert result.key?(:timestamp)

    assert_equal 1, result[:articles_count]
    assert_includes result[:sources], "TestSuccessfulFetcher"

    assert_equal "success", FetchRun.find_by(source_key: "test_successful_fetcher").status
    assert_equal "failure", FetchRun.find_by(source_key: "test_failing_fetcher").status
  end

  test "fetch_all_news reports handled fetch failures to Rails.error" do
    failing_fetcher = Object.new
    def failing_fetcher.fetch_articles
      raise StandardError, "API is down"
    end
    def failing_fetcher.source_key
      "test_report_fetcher"
    end
    def failing_fetcher.class
      OpenStruct.new(name: "TestReportFetcher")
    end

    @service.instance_variable_set(:@fetchers, [ failing_fetcher ])

    recorder = Class.new do
      attr_reader :reports

      def initialize
        @reports = []
      end

      def report(error, handled:, severity:, context:, source: nil)
        @reports << { error: error, handled: handled, severity: severity, context: context, source: source }
      end
    end.new

    Rails.error.subscribe(recorder)
    begin
      @service.fetch_all_news
    ensure
      Rails.error.unsubscribe(recorder)
    end

    assert_equal 1, recorder.reports.size
    report = recorder.reports.first
    assert_equal "news_fetch", report[:source]
    assert_equal true, report[:handled]
    assert_equal "test_report_fetcher", report[:context][:source_key]
    assert_equal "API is down", report[:error].message
  end

  test "class method fetch_all_news should work without live API calls" do
    mock_fetcher = Object.new
    def mock_fetcher.fetch_articles; []; end
    def mock_fetcher.class; OpenStruct.new(name: "MockFetcher"); end

    original = NewsAggregatorService.method(:build_fetchers)
    NewsAggregatorService.define_singleton_method(:build_fetchers) { [ mock_fetcher ] }
    begin
      result = NewsAggregatorService.fetch_all_news

      assert_kind_of Hash, result
      assert result.key?(:articles_count)
      assert result.key?(:duration)
      assert result.key?(:sources)
      assert result.key?(:timestamp)
    ensure
      NewsAggregatorService.define_singleton_method(:build_fetchers, original)
    end
  end

  test "fetch_all_news runs fetchers concurrently" do
    slow_fetcher = Object.new
    slow_fetcher.define_singleton_method(:fetch_articles) do
      sleep 0.3
      [ Article.new(title: "Slow", source_type: "slow") ]
    end
    slow_fetcher.define_singleton_method(:class) { OpenStruct.new(name: "SlowFetcher") }

    second_slow_fetcher = Object.new
    second_slow_fetcher.define_singleton_method(:fetch_articles) do
      sleep 0.3
      [ Article.new(title: "Slow2", source_type: "slow2") ]
    end
    second_slow_fetcher.define_singleton_method(:class) { OpenStruct.new(name: "SlowFetcherTwo") }

    @service.instance_variable_set(:@fetchers, [ slow_fetcher, second_slow_fetcher ])

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @service.fetch_all_news
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

    assert_operator elapsed, :<, 0.5, "expected parallel fetch (~0.3s), took #{elapsed.round(2)}s"
  end

  test "fetch_all_news should return proper structure" do
    # Mock fetchers to avoid actual API calls in this specific test
    mock_fetcher = Object.new
    def mock_fetcher.fetch_articles; []; end
    def mock_fetcher.class; OpenStruct.new(name: "MockFetcher"); end

    @service.instance_variable_set(:@fetchers, [ mock_fetcher ])

    result = @service.fetch_all_news

    assert_kind_of Hash, result
    assert_kind_of Integer, result[:articles_count]
    assert_kind_of Float, result[:duration]
    assert_kind_of Array, result[:sources]
    assert_kind_of Time, result[:timestamp]
    assert_equal 0, result[:articles_count]
    assert_includes result[:sources], "MockFetcher"
  end
end
