require "test_helper"

class YoutubeVideoEnricherTest < ActiveSupport::TestCase
  setup do
    @previous_key = ENV["YOUTUBE_API_KEY"]
    ENV["YOUTUBE_API_KEY"] = "test-key"

    @video = Article.create!(
      title: "Short tip",
      url: "https://www.youtube.com/watch?v=abc123XYZ",
      external_id: "abc123XYZ",
      source_type: "youtube_UCWnPjmqvljcafA0QXblOU1A",
      published_at: Time.current,
      content_type: "video",
      score: 10,
      comment_count: 0,
      duration_seconds: nil
    )
  end

  teardown do
    if @previous_key
      ENV["YOUTUBE_API_KEY"] = @previous_key
    else
      ENV.delete("YOUTUBE_API_KEY")
    end
  end

  test "enrich! fills duration and stats from videos.list" do
    stub_videos_list(
      items: [
        {
          "id" => "abc123XYZ",
          "contentDetails" => { "duration" => "PT7M32S" },
          "statistics" => { "viewCount" => "1500", "commentCount" => "12" }
        }
      ]
    )

    result = YoutubeVideoEnricher.enrich!

    assert_equal 1, result[:enriched]
    @video.reload
    assert_equal 452, @video.duration_seconds
    assert_equal 1500, @video.score
    assert_equal 12, @video.comment_count
  end

  test "parse_duration_seconds handles hours and seconds-only forms" do
    enricher = YoutubeVideoEnricher.new

    assert_equal 452, enricher.send(:parse_duration_seconds, "PT7M32S")
    assert_equal 3723, enricher.send(:parse_duration_seconds, "PT1H2M3S")
    assert_equal 45, enricher.send(:parse_duration_seconds, "PT45S")
    assert_nil enricher.send(:parse_duration_seconds, "not-a-duration")
    assert_nil enricher.send(:parse_duration_seconds, nil)
  end

  test "enrich! is a no-op without an API key" do
    ENV.delete("YOUTUBE_API_KEY")

    result = YoutubeVideoEnricher.enrich!

    assert result[:skipped]
    assert_equal 0, result[:enriched]
    assert_nil @video.reload.duration_seconds
  end

  test "enrich! reports quota errors without crashing or writing partial junk" do
    stub_request(:get, %r{https://www\.googleapis\.com/youtube/v3/videos})
      .to_return(
        status: 403,
        body: { error: { message: "quotaExceeded" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = YoutubeVideoEnricher.enrich!

    assert_equal 0, result[:enriched]
    assert_match(/HTTP 403/, result[:error])
    assert_nil @video.reload.duration_seconds
    assert_equal 10, @video.score
  end

  test "enrich! skips unparseable durations but still updates stats" do
    stub_videos_list(
      items: [
        {
          "id" => "abc123XYZ",
          "contentDetails" => { "duration" => "bogus" },
          "statistics" => { "viewCount" => "42", "commentCount" => "1" }
        }
      ]
    )

    result = YoutubeVideoEnricher.enrich!

    assert_equal 1, result[:enriched]
    @video.reload
    assert_nil @video.duration_seconds
    assert_equal 42, @video.score
    assert_equal 1, @video.comment_count
  end

  private

  def stub_videos_list(items:)
    stub_request(:get, %r{https://www\.googleapis\.com/youtube/v3/videos})
      .with(query: hash_including("part" => "contentDetails,statistics", "key" => "test-key"))
      .to_return(
        status: 200,
        body: { items: items }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
