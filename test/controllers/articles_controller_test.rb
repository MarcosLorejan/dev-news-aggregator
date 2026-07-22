require "test_helper"
require "active_job/test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def setup
    @article = articles(:hacker_news_article)
    @dev_to_article = articles(:dev_to_article)
    @rust_article = articles(:reddit_rust_article)
  end

  def count_queries
    count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") { count += 1 }
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  test "should get index" do
    get articles_url
    assert_response :success

    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "index should expose categories in JSON" do
    get articles_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["categories"].is_a?(Array)
    assert json_response["articles_by_category"].is_a?(Hash)
  end

  test "index JSON should exclude read articles by default" do
    @article.mark_as_read!

    get articles_url, as: :json
    assert_response :success

    titles = JSON.parse(response.body)["articles"].map { |article| article["title"] }
    assert_not_includes titles, @article.title
    assert_includes titles, @dev_to_article.title
  end

  test "index JSON should include read articles when show_read param is true" do
    @article.mark_as_read!

    get articles_url(show_read: true), as: :json
    assert_response :success

    titles = JSON.parse(response.body)["articles"].map { |article| article["title"] }
    assert_includes titles, @article.title
    assert_includes titles, @dev_to_article.title
  end

  test "index JSON should filter by min_score" do
    get articles_url(min_score: 100), as: :json
    assert_response :success

    scores = JSON.parse(response.body)["articles"].map { |article| article["score"] }
    assert scores.all? { |score| score >= 100 }
    assert_not_includes scores, @dev_to_article.score
  end

  test "index JSON should filter by top_percent" do
    get articles_url(top_percent: 50), as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert body["articles"].is_a?(Array)
    assert body["pagination"]["total_count"] <= Article.not_read.not_dismissed.count
  end

  test "fetch should enqueue FetchNewsJob" do
    assert_enqueued_with(job: FetchNewsJob) do
      post fetch_articles_url, as: :json
    end

    assert_response :accepted
    json = JSON.parse(response.body)
    assert_equal "queued", json["status"]
    assert json["job_id"].present?
  end

  test "fetch should rate limit repeated requests" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    begin
      post fetch_articles_url, as: :json
      assert_response :accepted

      post fetch_articles_url, as: :json
      assert_response :too_many_requests
    ensure
      Rails.cache = original_cache
    end
  end

  test "fetch rate limit uses atomic unless_exist write" do
    original_cache = Rails.cache
    store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache = store
    writes = []
    store.singleton_class.alias_method :original_write, :write
    store.define_singleton_method(:write) do |name, value, options = nil|
      writes << { name: name, options: options }
      original_write(name, value, options)
    end

    begin
      post fetch_articles_url, as: :json
      assert_response :accepted

      claim = writes.find { |entry| entry[:name].to_s.start_with?("articles_fetch:") }
      assert claim
      assert_equal true, claim[:options][:unless_exist]

      # A concurrent claim for the same key must fail while the window is held.
      assert_not store.write(
        claim[:name],
        Time.current,
        expires_in: ArticlesController::FETCH_RATE_LIMIT,
        unless_exist: true
      )

      post fetch_articles_url, as: :json
      assert_response :too_many_requests
    ensure
      Rails.cache = original_cache
    end
  end

  test "should get show" do
    get article_url(@article)
    assert_response :success

    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "show JSON should return article details" do
    get article_path(@article), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @article.id, json_response["id"]
    assert_equal @article.title, json_response["title"]
    assert json_response.key?("bookmarked")
    assert json_response.key?("read")
  end

  test "show JSON should include bookmark state" do
    get article_path(@article), as: :json
    assert_response :success
    refute JSON.parse(response.body)["bookmarked"]

    @article.bookmark!
    get article_path(@article), as: :json
    assert JSON.parse(response.body)["bookmarked"]
  end

  test "should bookmark article" do
    assert_not @article.bookmarked?

    post bookmark_article_path(@article)

    assert_redirected_to articles_path
    assert @article.reload.bookmarked?
  end

  test "should unbookmark article" do
    @article.create_bookmark
    assert @article.bookmarked?

    delete unbookmark_article_path(@article)

    assert_redirected_to articles_path
    assert_not @article.reload.bookmarked?
  end

  test "bookmark action should respond to JSON" do
    post bookmark_article_path(@article), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["bookmarked"]
    assert @article.reload.bookmarked?
  end

  test "double bookmark JSON is idempotent" do
    post bookmark_article_path(@article), as: :json
    assert_response :success

    assert_no_difference "Bookmark.count" do
      post bookmark_article_path(@article), as: :json
    end

    assert_response :success
    assert JSON.parse(response.body)["bookmarked"]
    assert_equal 1, Bookmark.where(article_id: @article.id).count
  end

  test "unbookmark action should respond to JSON" do
    @article.create_bookmark
    assert @article.bookmarked?

    delete unbookmark_article_path(@article), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal false, json_response["bookmarked"]
    @article.reload
    assert_not @article.bookmarked?
  end

  test "should handle non-existent article gracefully" do
    get article_url(id: 999999)

    assert_redirected_to articles_path
  end

  test "should handle bookmark of non-existent article as JSON" do
    post bookmark_article_path(id: 999999), as: :json

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Article not found", json_response["error"]
  end

  test "should handle bookmark of non-existent article" do
    post bookmark_article_path(id: 999999)

    assert_redirected_to articles_path
  end

  test "should dismiss article" do
    post dismiss_article_path(@article), headers: { "Accept" => "application/json" }

    assert_response :success
    assert @article.reload.pending_dismissal?

    response_data = JSON.parse(response.body)
    assert_equal "dismissed", response_data["status"]
    assert_equal 15, response_data["timeout"]
  end

  test "double dismiss JSON is idempotent" do
    post dismiss_article_path(@article), as: :json
    assert_response :success

    assert_no_difference "DismissedArticle.count" do
      post dismiss_article_path(@article), as: :json
    end

    assert_response :success
    assert_equal "dismissed", JSON.parse(response.body)["status"]
    assert_equal 1, DismissedArticle.where(article_id: @article.id).count
  end

  test "should undismiss article" do
    @article.dismiss!

    delete undismiss_article_path(@article), headers: { "Accept" => "application/json" }

    assert_response :success
    assert_not @article.reload.pending_dismissal?

    response_data = JSON.parse(response.body)
    assert_equal "restored", response_data["status"]
  end

  test "should handle dismiss with missing article" do
    post dismiss_article_path(99999), headers: { "Accept" => "application/json" }

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Article not found", json_response["error"]
  end

  test "should handle undismiss with missing article" do
    delete undismiss_article_path(99999)

    assert_redirected_to articles_path
    assert_equal "Article not found.", flash[:alert]
  end

  test "should exclude permanently dismissed articles from index JSON" do
    @article.dismiss!
    @article.dismissed_article.update!(permanent: true)

    get articles_path, as: :json

    assert_response :success
    titles = JSON.parse(response.body)["articles"].map { |article| article["title"] }
    assert_not_includes titles, @article.title
  end

  test "should include temporarily dismissed articles in index JSON" do
    @article.dismiss!

    get articles_path, as: :json

    assert_response :success
    titles = JSON.parse(response.body)["articles"].map { |article| article["title"] }
    assert_includes titles, @article.title
  end

  test "index should return JSON with articles" do
    get articles_url, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert json_response.key?("articles")
    assert json_response.key?("pagination")
    assert json_response.key?("categories")
    assert json_response.key?("articles_by_category")
    assert json_response.key?("category_counts")
    assert json_response.key?("last_updated")

    assert json_response["articles"].is_a?(Array)
    assert json_response["pagination"]["current_page"] == 1
    assert json_response["pagination"]["per_page"] == 50
  end

  test "index JSON should filter by category and keep full category counts" do
    get articles_url(category: "programming-languages"), as: :json
    assert_response :success

    body = JSON.parse(response.body)
    source_types = body["articles"].map { |article| article["source_type"] }
    assert source_types.all? { |source_type| %w[reddit_rust reddit_ruby reddit_javascript].include?(source_type) }
    assert_includes source_types, @rust_article.source_type
    assert_not_includes source_types, @article.source_type

    assert body["category_counts"]["Programming Languages"] >= 2
    assert body["category_counts"]["General Tech"] >= 2
    assert_equal body["articles"].size, body["pagination"]["total_count"]
    assert body["pagination"]["total_count"] < body["category_counts"].values.sum
  end

  test "index JSON category filter paginates across the filtered dataset" do
    5.times do |i|
      Article.create!(
        title: "Extra Rust #{i}",
        url: "https://example.com/rust-#{i}",
        external_id: "rust-extra-#{i}",
        source_type: "reddit_rust",
        published_at: i.hours.ago,
        score: 10,
        comment_count: 0
      )
    end

    get articles_url(category: "programming-languages", page: 1, per_page: 2), as: :json
    assert_response :success
    page_one = JSON.parse(response.body)

    get articles_url(category: "programming-languages", page: 2, per_page: 2), as: :json
    assert_response :success
    page_two = JSON.parse(response.body)

    assert_equal 2, page_one["articles"].size
    assert_operator page_two["articles"].size, :>=, 1
    assert_equal page_one["pagination"]["total_count"], page_two["pagination"]["total_count"]
    assert_operator page_one["pagination"]["total_pages"], :>=, 2

    page_one_ids = page_one["articles"].map { |article| article["id"] }
    page_two_ids = page_two["articles"].map { |article| article["id"] }
    assert_empty page_one_ids & page_two_ids

    assert_equal page_one["category_counts"], page_two["category_counts"]
    assert_equal page_one["category_counts"]["Programming Languages"], page_one["pagination"]["total_count"]
  end

  test "index JSON should return empty results for unknown category" do
    get articles_url(category: "not-a-real-category"), as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_empty body["articles"]
    assert_equal 0, body["pagination"]["total_count"]
    assert body["category_counts"].values.sum.positive?
  end

  test "index JSON should clamp invalid pagination params" do
    get articles_url(page: 0, per_page: 0), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal 1, json_response["pagination"]["current_page"]
    assert_equal 1, json_response["pagination"]["per_page"]
    assert json_response["pagination"]["total_pages"] >= 1
  end

  test "index JSON avoids N+1 queries for article state" do
    @article.bookmark!
    @dev_to_article.mark_as_read!

    query_count = count_queries do
      get articles_url, as: :json
    end

    assert_response :success
    assert_operator query_count, :<=, 15
  end

  test "index JSON should support pagination" do
    get articles_url(page: 2, per_page: 10), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal 2, json_response["pagination"]["current_page"]
    assert_equal 10, json_response["pagination"]["per_page"]
  end

  test "show should return JSON with article details" do
    get article_url(@article), as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal @article.id, json_response["id"]
    assert_equal @article.title, json_response["title"]
    assert_equal @article.url, json_response["url"]
    assert_equal @article.source_type, json_response["source_type"]
    assert json_response.key?("bookmarked")
    assert json_response.key?("read")
    assert json_response.key?("dismissed")
  end

  test "show should return 404 JSON for non-existent article" do
    get article_url(id: 999999), as: :json

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Article not found", json_response["error"]
  end

  test "undismiss should return 404 JSON for non-existent article" do
    delete undismiss_article_path(99999), as: :json

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Article not found", json_response["error"]
  end
end
