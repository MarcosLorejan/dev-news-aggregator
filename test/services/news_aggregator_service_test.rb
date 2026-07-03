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
