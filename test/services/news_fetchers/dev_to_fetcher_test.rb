require "test_helper"

class NewsFetchers::DevToFetcherTest < ActiveSupport::TestCase
  def setup
    @fetcher = NewsFetchers::DevToFetcher.new
  end

  test "fetch_articles creates articles from API response" do
    payload = [
      {
        "id" => 101,
        "title" => "Dev.to Post",
        "url" => "https://dev.to/user/post",
        "published_at" => "2024-01-15T12:00:00Z",
        "description" => "Summary",
        "positive_reactions_count" => 12,
        "comments_count" => 4
      }
    ]

    with_stubbed_get(NewsFetchers::DevToFetcher, lambda { |path, **_options|
      path == "/articles" ? payload : nil
    }) do
      assert_difference "Article.count", 1 do
        articles = @fetcher.fetch_articles
        assert_equal 1, articles.length
        assert_equal "Dev.to Post", articles.first.title
        assert_equal "dev_to", articles.first.source_type
        assert_equal 12, articles.first.score
      end
    end
  end

  test "fetch_articles returns empty array for invalid response" do
    stub_request(:get, %r{https://dev\.to/api/articles})
      .to_return(status: 200, body: { error: "bad" }.to_json, headers: { "Content-Type" => "application/json" })

    assert_no_difference "Article.count" do
      assert_empty @fetcher.fetch_articles
    end
  end

  test "fetch_articles does not abort the run for malformed article payloads" do
    with_stubbed_get(NewsFetchers::DevToFetcher, lambda { |path, **_options|
      path == "/articles" ? [ { "id" => 202, "title" => nil, "url" => "https://dev.to/user/bad", "published_at" => "2024-01-15T12:00:00Z" } ] : nil
    }) do
      assert_nothing_raised do
        assert_kind_of Array, @fetcher.fetch_articles
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
