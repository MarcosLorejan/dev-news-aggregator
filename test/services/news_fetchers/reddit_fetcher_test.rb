require "test_helper"

class NewsFetchers::RedditFetcherTest < ActiveSupport::TestCase
  def setup
    @fetcher = NewsFetchers::RedditFetcher.new(subreddit: "programming")
    NewsFetchers::RedditFetcher.min_request_interval_seconds = 0
    NewsFetchers::RedditFetcher.reset_throttle!
  end

  def teardown
    NewsFetchers::RedditFetcher.min_request_interval_seconds = nil
    NewsFetchers::RedditFetcher.reset_throttle!
  end

  test "fetch_articles creates articles from Atom link posts" do
    stub_reddit_feed(<<~ATOM)
      <feed xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <id>t3_abc123</id>
          <title>Reddit Link</title>
          <link href="https://www.reddit.com/r/programming/comments/abc123/reddit_link/" />
          <published>2023-11-14T22:13:20+00:00</published>
          <content type="html">submitted by /u/someone &lt;a href="https://example.com/article"&gt;[link]&lt;/a&gt; &lt;a href="https://www.reddit.com/r/programming/comments/abc123/reddit_link/"&gt;[comments]&lt;/a&gt;</content>
        </entry>
      </feed>
    ATOM

    assert_difference "Article.count", 1 do
      articles = @fetcher.fetch_articles
      assert_equal 1, articles.length
      assert_equal "Reddit Link", articles.first.title
      assert_equal "https://example.com/article", articles.first.url
      assert_equal "reddit_programming", articles.first.source_type
      assert_equal "abc123", articles.first.external_id
    end
  end

  test "fetch_articles uses permalink when link points at Reddit" do
    stub_reddit_feed(<<~ATOM)
      <feed xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <id>t3_self1</id>
          <title>Self post</title>
          <link href="https://www.reddit.com/r/programming/comments/self1/title/" />
          <published>2023-11-14T22:13:20+00:00</published>
          <content type="html">&lt;a href="https://www.reddit.com/r/programming/comments/self1/title/"&gt;[link]&lt;/a&gt;</content>
        </entry>
      </feed>
    ATOM

    assert_difference "Article.count", 1 do
      article = @fetcher.fetch_articles.first
      assert_equal "https://www.reddit.com/r/programming/comments/self1/title/", article.url
    end
  end

  test "fetch_articles raises when Reddit returns HTTP errors" do
    stub_request(:get, "https://www.reddit.com/r/programming/.rss")
      .to_return(status: 403, body: "<html>Blocked</html>", headers: { "Content-Type" => "text/html" })

    error = assert_raises(NewsFetchers::BaseFetcher::FetchError) do
      @fetcher.fetch_articles
    end
    assert_match(/HTTP 403/, error.message)
  end

  test "fetch_articles raises when feed has no entries" do
    stub_reddit_feed(<<~ATOM)
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>programming</title>
      </feed>
    ATOM

    assert_raises(NewsFetchers::BaseFetcher::FetchError) do
      @fetcher.fetch_articles
    end
  end

  test "fetch_articles preserves existing score and comment_count on update" do
    Article.create!(
      title: "Old Title",
      url: "https://example.com/old",
      published_at: 1.day.ago,
      description: "old",
      external_id: "abc123",
      source_type: "reddit_programming",
      score: 42,
      comment_count: 7
    )

    stub_reddit_feed(<<~ATOM)
      <feed xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <id>t3_abc123</id>
          <title>Updated Title</title>
          <link href="https://www.reddit.com/r/programming/comments/abc123/reddit_link/" />
          <published>2023-11-14T22:13:20+00:00</published>
          <content type="html">&lt;a href="https://example.com/article"&gt;[link]&lt;/a&gt;</content>
        </entry>
      </feed>
    ATOM

    assert_no_difference "Article.count" do
      article = @fetcher.fetch_articles.first
      assert_equal "Updated Title", article.title
      assert_equal "https://example.com/article", article.url
      assert_equal 42, article.score
      assert_equal 7, article.comment_count
    end
  end

  test "extract_article_url keeps external hosts that contain reddit.com as a substring" do
    url = @fetcher.send(
      :extract_article_url,
      %(<a href="https://notreddit.com/post">[link]</a>),
      "https://www.reddit.com/r/programming/comments/x/title/"
    )
    assert_equal "https://notreddit.com/post", url
  end

  private

  def stub_reddit_feed(body)
    stub_request(:get, "https://www.reddit.com/r/programming/.rss")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/atom+xml" })
  end
end
