require "test_helper"

class NewsFetchers::RedditFetcherTest < ActiveSupport::TestCase
  def setup
    @fetcher = NewsFetchers::RedditFetcher.new(subreddit: "programming")
  end

  test "fetch_articles creates articles from link posts" do
    stub_request(:get, "https://www.reddit.com/r/programming.json")
      .with(query: { limit: 25 })
      .to_return(
        status: 200,
        body: {
          data: {
            children: [
              {
                data: {
                  id: "abc123",
                  title: "Reddit Link",
                  url_overridden_by_dest: "https://example.com/article",
                  created_utc: 1_700_000_000,
                  selftext: "",
                  is_self: false,
                  score: 50,
                  num_comments: 8
                }
              }
            ]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Article.count", 1 do
      articles = @fetcher.fetch_articles
      assert_equal 1, articles.length
      assert_equal "Reddit Link", articles.first.title
      assert_equal "reddit_programming", articles.first.source_type
    end
  end

  test "fetch_articles skips self posts without external URL" do
    stub_request(:get, "https://www.reddit.com/r/programming.json")
      .with(query: { limit: 25 })
      .to_return(
        status: 200,
        body: {
          data: {
            children: [
              {
                data: {
                  id: "self1",
                  title: "Self post",
                  is_self: true,
                  permalink: "/r/programming/comments/self1/title/",
                  created_utc: 1_700_000_000,
                  score: 1,
                  num_comments: 0
                }
              }
            ]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_no_difference "Article.count" do
      assert_empty @fetcher.fetch_articles
    end
  end

  test "fetch_articles uses overridden URL for self posts with external link" do
    stub_request(:get, "https://www.reddit.com/r/programming.json")
      .with(query: { limit: 25 })
      .to_return(
        status: 200,
        body: {
          data: {
            children: [
              {
                data: {
                  id: "self2",
                  title: "Self with link",
                  is_self: true,
                  url_overridden_by_dest: "https://example.com/linked",
                  permalink: "/r/programming/comments/self2/title/",
                  created_utc: 1_700_000_000,
                  score: 2,
                  num_comments: 1
                }
              }
            ]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Article.count", 1 do
      article = @fetcher.fetch_articles.first
      assert_equal "https://example.com/linked", article.url
    end
  end

  test "fetch_articles returns empty array when API response is invalid" do
    stub_request(:get, "https://www.reddit.com/r/programming.json")
      .with(query: { limit: 25 })
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

    assert_no_difference "Article.count" do
      assert_empty @fetcher.fetch_articles
    end
  end
end
