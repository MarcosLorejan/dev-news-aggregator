require "test_helper"

class NewsFetchers::YoutubeFetcherTest < ActiveSupport::TestCase
  setup do
    NewsFetchers::YoutubeFetcher.reset_throttle!
    NewsFetchers::YoutubeFetcher.min_request_interval_seconds = 0
    NewsFetchers::YoutubeFetcher.rate_limit_backoff_seconds = 0
    NewsFetchers::YoutubeFetcher.rate_limit_jitter_factor = 0
    @channel_id = "UCWnPjmqvljcafA0QXblOU1A"
    @fetcher = NewsFetchers::YoutubeFetcher.new(channel_id: @channel_id, channel_name: "Confreaks")
  end

  teardown do
    NewsFetchers::YoutubeFetcher.min_request_interval_seconds = nil
    NewsFetchers::YoutubeFetcher.rate_limit_backoff_seconds = nil
    NewsFetchers::YoutubeFetcher.rate_limit_jitter_factor = nil
    NewsFetchers::YoutubeFetcher.reset_throttle!
  end

  test "source_key includes the channel id" do
    assert_equal "youtube_#{@channel_id}", @fetcher.source_key
  end

  test "fetch_articles creates video articles from the Atom feed" do
    stub_youtube_feed(<<~ATOM)
      <feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
            xmlns:media="http://search.yahoo.com/mrss/"
            xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <id>yt:video:abc123XYZ</id>
          <yt:videoId>abc123XYZ</yt:videoId>
          <title>Rails performance tips</title>
          <link rel="alternate" href="https://www.youtube.com/watch?v=abc123XYZ"/>
          <author><name>Confreaks</name></author>
          <published>2024-06-01T12:00:00+00:00</published>
          <media:group>
            <media:description>A talk about Rails performance.</media:description>
            <media:thumbnail url="https://i.ytimg.com/vi/abc123XYZ/hqdefault.jpg"/>
            <media:community>
              <media:statistics views="1234"/>
            </media:community>
          </media:group>
        </entry>
      </feed>
    ATOM

    assert_difference "Article.count", 1 do
      articles = @fetcher.fetch_articles
      assert_equal 1, articles.length
    end

    article = Article.find_by!(external_id: "abc123XYZ", source_type: "youtube_#{@channel_id}")
    assert_equal "Rails performance tips", article.title
    assert_equal "https://www.youtube.com/watch?v=abc123XYZ", article.url
    assert_equal "video", article.content_type
    assert_equal "Confreaks", article.author
    assert_equal "https://i.ytimg.com/vi/abc123XYZ/maxresdefault.jpg", article.thumbnail_url
    assert_equal 1234, article.score
    assert_equal 0, article.comment_count
    assert_equal "A talk about Rails performance.", article.description
  end

  test "fetch_articles skips Shorts by URL or #shorts title" do
    stub_youtube_feed(<<~ATOM)
      <feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
            xmlns:media="http://search.yahoo.com/mrss/"
            xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <yt:videoId>shortAAA</yt:videoId>
          <title>Quick tip</title>
          <link rel="alternate" href="https://www.youtube.com/shorts/shortAAA"/>
          <published>2024-06-01T12:00:00+00:00</published>
          <media:group>
            <media:thumbnail url="https://i.ytimg.com/vi/shortAAA/hqdefault.jpg"/>
          </media:group>
        </entry>
        <entry>
          <yt:videoId>shortBBB</yt:videoId>
          <title>Another tip #shorts</title>
          <link rel="alternate" href="https://www.youtube.com/watch?v=shortBBB"/>
          <published>2024-06-01T13:00:00+00:00</published>
          <media:group>
            <media:thumbnail url="https://i.ytimg.com/vi/shortBBB/hqdefault.jpg"/>
          </media:group>
        </entry>
        <entry>
          <yt:videoId>longCCC</yt:videoId>
          <title>Full tutorial</title>
          <link rel="alternate" href="https://www.youtube.com/watch?v=longCCC"/>
          <published>2024-06-01T14:00:00+00:00</published>
          <media:group>
            <media:thumbnail url="https://i.ytimg.com/vi/longCCC/hqdefault.jpg"/>
          </media:group>
        </entry>
      </feed>
    ATOM

    assert_difference "Article.count", 1 do
      articles = @fetcher.fetch_articles
      assert_equal 1, articles.length
    end

    assert Article.exists?(external_id: "longCCC", source_type: "youtube_#{@channel_id}")
    assert_not Article.exists?(external_id: "shortAAA")
    assert_not Article.exists?(external_id: "shortBBB")
  end

  test "fetch_articles updates existing videos without wiping a higher score when views are missing" do
    existing = Article.create!(
      title: "Old title",
      url: "https://www.youtube.com/watch?v=abc123XYZ",
      external_id: "abc123XYZ",
      source_type: "youtube_#{@channel_id}",
      published_at: 1.day.ago,
      content_type: "video",
      score: 9999,
      comment_count: 0
    )

    stub_youtube_feed(<<~ATOM)
      <feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
            xmlns:media="http://search.yahoo.com/mrss/"
            xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <yt:videoId>abc123XYZ</yt:videoId>
          <title>Updated title</title>
          <link rel="alternate" href="https://www.youtube.com/watch?v=abc123XYZ"/>
          <published>2024-06-02T12:00:00+00:00</published>
          <media:group>
            <media:description>Updated</media:description>
            <media:thumbnail url="https://i.ytimg.com/vi/abc123XYZ/hqdefault.jpg"/>
          </media:group>
        </entry>
      </feed>
    ATOM

    assert_no_difference "Article.count" do
      @fetcher.fetch_articles
    end

    existing.reload
    assert_equal "Updated title", existing.title
    assert_equal 9999, existing.score
  end

  test "fetch_articles raises on HTTP 404" do
    stub_request(:get, feed_url)
      .to_return(status: 404, body: "Not Found", headers: { "Content-Type" => "text/plain" })

    error = assert_raises(NewsFetchers::BaseFetcher::FetchError) { @fetcher.fetch_articles }
    assert_match(/HTTP 404/, error.message)
  end

  test "fetch_articles raises on HTTP 5xx" do
    stub_request(:get, feed_url)
      .to_return(status: 503, body: "Unavailable", headers: { "Content-Type" => "text/plain" })

    error = assert_raises(NewsFetchers::BaseFetcher::FetchError) { @fetcher.fetch_articles }
    assert_match(/HTTP 503/, error.message)
  end

  test "fetch_articles raises when the feed has no entries" do
    stub_youtube_feed(<<~ATOM)
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Empty channel</title>
      </feed>
    ATOM

    error = assert_raises(NewsFetchers::BaseFetcher::FetchError) { @fetcher.fetch_articles }
    assert_match(/no entries/, error.message)
  end

  test "fetch_articles raises on an empty body" do
    stub_request(:get, feed_url)
      .to_return(status: 200, body: "", headers: { "Content-Type" => "application/atom+xml" })

    error = assert_raises(NewsFetchers::BaseFetcher::FetchError) { @fetcher.fetch_articles }
    assert_match(/Empty YouTube/, error.message)
  end

  test "fetch_articles retries after HTTP 429" do
    stub_request(:get, feed_url)
      .to_return(
        { status: 429, body: "rate limited", headers: { "Content-Type" => "text/plain" } },
        { status: 200, body: single_entry_atom, headers: { "Content-Type" => "application/atom+xml" } }
      )

    articles = @fetcher.fetch_articles
    assert_equal 1, articles.length
  end

  private

  def feed_url
    "https://www.youtube.com/feeds/videos.xml?channel_id=#{@channel_id}"
  end

  def stub_youtube_feed(body)
    stub_request(:get, feed_url)
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/atom+xml" })
  end

  def single_entry_atom
    <<~ATOM
      <feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
            xmlns:media="http://search.yahoo.com/mrss/"
            xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <yt:videoId>retryVid1</yt:videoId>
          <title>After retry</title>
          <link rel="alternate" href="https://www.youtube.com/watch?v=retryVid1"/>
          <published>2024-06-01T12:00:00+00:00</published>
          <media:group>
            <media:description>ok</media:description>
            <media:thumbnail url="https://i.ytimg.com/vi/retryVid1/hqdefault.jpg"/>
          </media:group>
        </entry>
      </feed>
    ATOM
  end
end
