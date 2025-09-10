require "test_helper"

class NewsAggregatorServiceTest < ActiveSupport::TestCase
  def setup
    @service = NewsAggregatorService.new
  end

  test "should initialize with multiple fetchers" do
    fetchers = @service.instance_variable_get(:@fetchers)

    assert fetchers.length > 1
    assert fetchers.any? { |f| f.is_a?(NewsFetchers::HackerNewsFetcher) }
    assert fetchers.any? { |f| f.is_a?(NewsFetchers::DevToFetcher) }
    assert fetchers.count { |f| f.is_a?(NewsFetchers::RedditFetcher) } > 1
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
  end

  test "class method fetch_all_news should work" do
    # This will actually run the service but that's okay for integration testing
    result = NewsAggregatorService.fetch_all_news

    assert_kind_of Hash, result
    assert result.key?(:articles_count)
    assert result.key?(:duration)
    assert result.key?(:sources)
    assert result.key?(:timestamp)
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
