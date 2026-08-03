require "test_helper"

class YoutubeKeywordDiscoveryTest < ActiveSupport::TestCase
  setup do
    @previous_key = ENV["YOUTUBE_API_KEY"]
    ENV["YOUTUBE_API_KEY"] = "test-key"
    NewsAggregatorConfig.reset!
    YoutubeKeywordDiscovery.call_store = ActiveSupport::Cache::MemoryStore.new

    @ruby = keyword_filters(:ruby_interest)
    @rust = keyword_filters(:rust_interest)
  end

  teardown do
    if @previous_key
      ENV["YOUTUBE_API_KEY"] = @previous_key
    else
      ENV.delete("YOUTUBE_API_KEY")
    end
    NewsAggregatorConfig.reset!
    YoutubeKeywordDiscovery.reset_call_store!
  end

  test "run! is a no-op when search is disabled" do
    result = YoutubeKeywordDiscovery.run!

    assert result[:skipped]
    assert_equal 0, result[:created]
    assert_equal 0, result[:searched]
  end

  test "run! is a no-op without an API key even when enabled" do
    ENV.delete("YOUTUBE_API_KEY")

    with_search_enabled do
      result = YoutubeKeywordDiscovery.run!

      assert result[:skipped]
      assert_equal 0, result[:created]
    end
  end

  test "run! searches enabled filters and creates video articles" do
    stub_search_list(
      query: "ruby|rubygems",
      items: [ search_item(video_id: "rubyVid001", title: "Rails tip", channel: "Confreaks") ]
    )
    stub_search_list(
      query: "rust|cargo",
      items: [ search_item(video_id: "rustVid001", title: "Ownership", channel: "Jon Gjengset") ]
    )

    result = nil
    with_search_enabled do
      result = YoutubeKeywordDiscovery.run!
    end

    assert_equal 2, result[:created]
    assert_equal 2, result[:searched]
    refute result[:skipped]

    ruby_video = Article.find_by!(external_id: "rubyVid001")
    assert_equal "video", ruby_video.content_type
    assert_equal "youtube_search_ruby", ruby_video.source_type
    assert_equal "Confreaks", ruby_video.author
    assert_equal "https://i.ytimg.com/vi/rubyVid001/hqdefault.jpg", ruby_video.thumbnail_url

    assert FetchRun.exists?(source_key: "youtube_search_ruby", status: "success")
    assert FetchRun.exists?(source_key: "youtube_search_rust", status: "success")
  end

  test "run! does not search inactive keyword filters" do
    stub_search_list(query: "ruby|rubygems", items: [])
    stub_search_list(query: "rust|cargo", items: [])

    with_search_enabled do
      YoutubeKeywordDiscovery.run!
    end

    assert_not FetchRun.exists?(source_key: "youtube_search_elixir")
    assert_requested :get, %r{youtube/v3/search}, times: 2
  end

  test "run! skips videos already ingested from channel feeds" do
    Article.create!(
      title: "Already from channel",
      url: "https://www.youtube.com/watch?v=dupVid001",
      external_id: "dupVid001",
      source_type: "youtube_UCWnPjmqvljcafA0QXblOU1A",
      published_at: Time.current,
      content_type: "video",
      score: 5,
      comment_count: 0
    )

    stub_search_list(
      query: "ruby|rubygems",
      items: [ search_item(video_id: "dupVid001", title: "Duplicate hit") ]
    )
    stub_search_list(query: "rust|cargo", items: [])

    result = nil
    with_search_enabled do
      result = YoutubeKeywordDiscovery.run!
    end

    assert_equal 0, result[:created]
    assert_equal 1, Article.where(external_id: "dupVid001").count
    refute Article.exists?(source_type: "youtube_search_ruby", external_id: "dupVid001")
  end

  test "run! enforces the daily search call budget" do
    stub_search_list(
      query: "ruby|rubygems",
      items: [ search_item(video_id: "budgetVid1", title: "First") ]
    )

    result = nil
    with_config_overrides(
      youtube_search_enabled?: true,
      youtube_search_daily_call_budget: 1,
      youtube_search_min_interval_hours: 0
    ) do
      result = YoutubeKeywordDiscovery.run!
    end

    assert_equal 1, result[:searched]
    assert result[:budget_exhausted]
    assert_equal 1, Article.where(external_id: "budgetVid1").count
    assert_not FetchRun.exists?(source_key: "youtube_search_rust")
  end

  test "run! respects per-filter minimum interval" do
    FetchRun.record_outcome(
      source_key: "youtube_search_ruby",
      status: "success",
      articles_count: 0
    )
    ruby_finished_at = FetchRun.find_by!(source_key: "youtube_search_ruby").finished_at

    stub_search_list(query: "rust|cargo", items: [])

    with_config_overrides(youtube_search_enabled?: true) do
      YoutubeKeywordDiscovery.run!
    end

    assert_requested :get, %r{youtube/v3/search}, times: 1
    assert_equal ruby_finished_at.to_i, FetchRun.find_by!(source_key: "youtube_search_ruby").finished_at.to_i
    assert FetchRun.exists?(source_key: "youtube_search_rust", status: "success")
  end

  test "run! records failure and stops on quota errors without raising" do
    stub_request(:get, %r{https://www\.googleapis\.com/youtube/v3/search})
      .to_return(
        status: 403,
        body: { error: { message: "quotaExceeded" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = nil
    with_search_enabled do
      assert_nothing_raised do
        result = YoutubeKeywordDiscovery.run!
      end
    end

    assert_equal 0, result[:created]
    failure = FetchRun.find_by(source_key: "youtube_search_ruby")
    assert failure
    assert_equal "failure", failure.status
    assert_match(/403/, failure.error_message)
  end

  private

  def with_search_enabled
    with_config_overrides(
      youtube_search_enabled?: true,
      youtube_search_min_interval_hours: 0
    ) { yield }
  end

  def with_config_overrides(overrides)
    originals = {}
    overrides.each do |name, return_value|
      originals[name] = NewsAggregatorConfig.method(name)
      captured = return_value
      NewsAggregatorConfig.define_singleton_method(name) { captured }
    end
    yield
  ensure
    originals.each do |name, original|
      NewsAggregatorConfig.define_singleton_method(name) { |*args, **kwargs, &block|
        original.call(*args, **kwargs, &block)
      }
    end
  end

  def search_item(video_id:, title:, channel: "Example Channel")
    {
      "id" => { "videoId" => video_id },
      "snippet" => {
        "title" => title,
        "description" => "A talk about #{title}",
        "publishedAt" => "2024-06-01T12:00:00Z",
        "channelTitle" => channel,
        "thumbnails" => {
          "high" => { "url" => "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg" }
        }
      }
    }
  end

  def stub_search_list(query:, items:)
    stub_request(:get, %r{https://www\.googleapis\.com/youtube/v3/search})
      .with(query: hash_including("q" => query, "type" => "video", "key" => "test-key"))
      .to_return(
        status: 200,
        body: { items: items }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
