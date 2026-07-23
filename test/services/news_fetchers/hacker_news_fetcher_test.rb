require "test_helper"

class NewsFetchers::HackerNewsFetcherTest < ActiveSupport::TestCase
  def setup
    @fetcher = NewsFetchers::HackerNewsFetcher.new
  end

  test "fetch_articles creates articles from story payloads" do
    story = {
      "id" => 88_001,
      "type" => "story",
      "title" => "HN Story",
      "url" => "https://example.com/story",
      "time" => 1_700_000_000,
      "score" => 10,
      "descendants" => 3
    }

    with_stubbed_get(NewsFetchers::HackerNewsFetcher, lambda { |path, **_options|
      case path
      when "/topstories.json" then [ 88_001 ]
      when "/item/88001.json" then story
      end
    }) do
      assert_difference "Article.count", 1 do
        articles = @fetcher.fetch_articles
        assert_equal 1, articles.length
        assert_equal "HN Story", articles.first.title
        assert_equal "hacker_news", articles.first.source_type
      end
    end
  end

  test "fetch_articles skips stories without URLs" do
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: [ 99 ].to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/99.json")
      .to_return(
        status: 200,
        body: {
          id: 99,
          type: "story",
          title: "Ask HN: Question",
          time: 1_700_000_000
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_no_difference "Article.count" do
      assert_empty @fetcher.fetch_articles
    end
  end

  test "fetch_articles raises when top stories request fails" do
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 500, body: "error")

    assert_no_difference "Article.count" do
      error = assert_raises(NewsFetchers::BaseFetcher::FetchError) do
        @fetcher.fetch_articles
      end
      assert_match(/HTTP 500/, error.message)
    end
  end

  test "fetch_articles fetches story items concurrently" do
    story_ids = [ 88_101, 88_102, 88_103 ]
    stories = story_ids.map do |id|
      {
        "id" => id,
        "type" => "story",
        "title" => "HN Story #{id}",
        "url" => "https://example.com/#{id}",
        "time" => 1_700_000_000,
        "score" => 1,
        "descendants" => 0
      }
    end

    with_stubbed_get(NewsFetchers::HackerNewsFetcher, lambda { |path, **_options|
      return story_ids if path == "/topstories.json"

      if (match = path.match(%r{\A/item/(\d+)\.json\z}))
        sleep 0.2
        stories.find { |story| story["id"] == match[1].to_i }
      end
    }) do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      articles = @fetcher.fetch_articles
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      assert_equal 3, articles.length
      assert_operator elapsed, :<, 0.5, "expected parallel item fetch (~0.2s), took #{elapsed.round(2)}s"
    end
  end

  test "fetch_articles continues when one story item fails" do
    good_story = {
      "id" => 88_201,
      "type" => "story",
      "title" => "Good HN Story",
      "url" => "https://example.com/good",
      "time" => 1_700_000_000,
      "score" => 5,
      "descendants" => 1
    }

    with_stubbed_get(NewsFetchers::HackerNewsFetcher, lambda { |path, **_options|
      case path
      when "/topstories.json"
        [ 88_201, 88_202 ]
      when "/item/88201.json"
        good_story
      when "/item/88202.json"
        raise NewsFetchers::BaseFetcher::FetchError, "HTTP 500 for item"
      end
    }) do
      assert_difference "Article.count", 1 do
        articles = @fetcher.fetch_articles
        assert_equal 1, articles.length
        assert_equal "Good HN Story", articles.first.title
      end
    end
  end

  private

  def with_stubbed_get(fetcher_class, implementation)
    original = fetcher_class.method(:get)
    fetcher_class.define_singleton_method(:get, implementation)
    yield
  ensure
    fetcher_class.define_singleton_method(:get, original)
  end
end
