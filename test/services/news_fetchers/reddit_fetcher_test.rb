require "test_helper"

class NewsFetchers::RedditFetcherTest < ActiveSupport::TestCase
  def setup
    @fetcher = NewsFetchers::RedditFetcher.new(subreddit: "programming")
    NewsFetchers::RedditFetcher.min_request_interval_seconds = 0
    NewsFetchers::RedditFetcher.reset_throttle!
    NewsFetchers::RedditFetcher.reset_oauth_token!
    @previous_client_id = ENV["REDDIT_CLIENT_ID"]
    @previous_client_secret = ENV["REDDIT_CLIENT_SECRET"]
    ENV.delete("REDDIT_CLIENT_ID")
    ENV.delete("REDDIT_CLIENT_SECRET")
  end

  def teardown
    NewsFetchers::RedditFetcher.min_request_interval_seconds = nil
    NewsFetchers::RedditFetcher.rate_limit_backoff_seconds = nil
    NewsFetchers::RedditFetcher.reset_throttle!
    NewsFetchers::RedditFetcher.reset_oauth_token!
    if @previous_client_id
      ENV["REDDIT_CLIENT_ID"] = @previous_client_id
    else
      ENV.delete("REDDIT_CLIENT_ID")
    end
    if @previous_client_secret
      ENV["REDDIT_CLIENT_SECRET"] = @previous_client_secret
    else
      ENV.delete("REDDIT_CLIENT_SECRET")
    end
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
      assert_equal 0, articles.first.score
      assert_equal 0, articles.first.comment_count
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

  test "fetch_articles retries HTTP 429 then succeeds" do
    stub_request(:get, "https://www.reddit.com/r/programming/.rss")
      .to_return(
        { status: 429, body: "", headers: { "Content-Type" => "text/html" } },
        {
          status: 200,
          body: <<~ATOM,
            <feed xmlns="http://www.w3.org/2005/Atom">
              <entry>
                <id>t3_retry1</id>
                <title>After Retry</title>
                <link href="https://www.reddit.com/r/programming/comments/retry1/title/" />
                <published>2023-11-14T22:13:20+00:00</published>
                <content type="html">&lt;a href="https://example.com/ok"&gt;[link]&lt;/a&gt;</content>
              </entry>
            </feed>
          ATOM
          headers: { "Content-Type" => "application/atom+xml" }
        }
      )

    NewsFetchers::RedditFetcher.rate_limit_backoff_seconds = 0
    assert_difference "Article.count", 1 do
      article = @fetcher.fetch_articles.first
      assert_equal "After Retry", article.title
      assert_equal "retry1", article.external_id
    end
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

  test "fetch_articles preserves existing score and comment_count on Atom update" do
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

  test "fetch_articles via OAuth JSON persists score and comment_count" do
    ENV["REDDIT_CLIENT_ID"] = "test-client-id"
    ENV["REDDIT_CLIENT_SECRET"] = "test-client-secret"

    stub_request(:post, "https://www.reddit.com/api/v1/access_token")
      .to_return(
        status: 200,
        body: { access_token: "token-123", expires_in: 3600, token_type: "bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://oauth.reddit.com/r/programming/hot")
      .with(query: hash_including("limit" => "5", "raw_json" => "1"))
      .to_return(
        status: 200,
        body: {
          data: {
            children: [
              {
                kind: "t3",
                data: {
                  id: "xyz789",
                  title: "OAuth Post",
                  url: "https://example.com/oauth-article",
                  permalink: "/r/programming/comments/xyz789/oauth_post/",
                  created_utc: 1_700_000_000,
                  selftext: "Body text",
                  score: 321,
                  num_comments: 45
                }
              }
            ]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Article.count", 1 do
      article = @fetcher.fetch_articles.first
      assert_equal "OAuth Post", article.title
      assert_equal "https://example.com/oauth-article", article.url
      assert_equal "xyz789", article.external_id
      assert_equal "reddit_programming", article.source_type
      assert_equal 321, article.score
      assert_equal 45, article.comment_count
    end
  end

  test "oauth JSON path retries HTTP 429 then succeeds" do
    ENV["REDDIT_CLIENT_ID"] = "test-client-id"
    ENV["REDDIT_CLIENT_SECRET"] = "test-client-secret"

    stub_request(:post, "https://www.reddit.com/api/v1/access_token")
      .to_return(
        status: 200,
        body: { access_token: "token-123", expires_in: 3600, token_type: "bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://oauth.reddit.com/r/programming/hot")
      .with(query: hash_including("limit"))
      .to_return(
        { status: 429, body: "", headers: { "Content-Type" => "text/html" } },
        {
          status: 200,
          body: {
            data: {
              children: [
                {
                  kind: "t3",
                  data: {
                    id: "retryoauth",
                    title: "OAuth After Retry",
                    url: "https://example.com/retry",
                    permalink: "/r/programming/comments/retryoauth/title/",
                    created_utc: 1_700_000_100,
                    selftext: "",
                    score: 12,
                    num_comments: 3
                  }
                }
              ]
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        }
      )

    NewsFetchers::RedditFetcher.rate_limit_backoff_seconds = 0
    article = @fetcher.fetch_articles.first
    assert_equal "OAuth After Retry", article.title
    assert_equal 12, article.score
  end

  test "MachineLearning subreddit source_key and Atom ingestion" do
    fetcher = NewsFetchers::RedditFetcher.new(subreddit: "MachineLearning")
    stub_request(:get, "https://www.reddit.com/r/MachineLearning/.rss")
      .to_return(
        status: 200,
        body: <<~ATOM,
          <feed xmlns="http://www.w3.org/2005/Atom">
            <entry>
              <id>t3_ml001</id>
              <title>ML Paper</title>
              <link href="https://www.reddit.com/r/MachineLearning/comments/ml001/ml_paper/" />
              <published>2023-11-14T22:13:20+00:00</published>
              <content type="html">&lt;a href="https://arxiv.org/abs/1234"&gt;[link]&lt;/a&gt;</content>
            </entry>
          </feed>
        ATOM
        headers: { "Content-Type" => "application/atom+xml" }
      )

    assert_equal "reddit_MachineLearning", fetcher.source_key
    article = fetcher.fetch_articles.first
    assert_equal "reddit_MachineLearning", article.source_type
    assert_equal "ml001", article.external_id
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
