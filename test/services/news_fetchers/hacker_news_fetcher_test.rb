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

  test "fetch_articles returns empty array when top stories request fails" do
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 500, body: "error")

    assert_no_difference "Article.count" do
      assert_empty @fetcher.fetch_articles
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
