require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @article = articles(:hacker_news_article)
    @dev_to_article = articles(:dev_to_article)
    @rust_article = articles(:reddit_rust_article)
  end

  test "should get index" do
    get articles_url
    assert_response :success

    assert_select "article.article-card", minimum: 1
    assert_select "h1", "Developer News Aggregator"
  end

  test "index should show articles grouped by source" do
    get articles_url
    assert_response :success

    assert_select "button[data-filter-type='all']", text: /All Articles/
    assert_select "button[data-filter-type='category']", minimum: 1
  end

  test "index should show reading list link" do
    get articles_url
    assert_response :success

    assert_select "a[href='#{bookmarks_path}']", "Reading List"
  end

  test "index should show already read link" do
    get articles_url
    assert_response :success

    assert_select "a[href='#{read_articles_path}']", "Already Read"
  end

  test "index should exclude read articles by default" do
    @article.mark_as_read!

    get articles_url
    assert_response :success

    assert_select "h2", text: @article.title, count: 0
    assert_select "h2", text: @dev_to_article.title, count: 1
  end

  test "index should include read articles when show_read param is true" do
    @article.mark_as_read!

    get articles_url(show_read: true)
    assert_response :success

    assert_select "h2", text: @article.title, count: 1
    assert_select "h2", text: @dev_to_article.title, count: 1
  end

  test "should get show" do
    get article_url(@article)
    assert_response :success

    assert_select "h1", @article.title
    assert_select "a[href='#{@article.url}'][target='_blank']", "Visit Source"
  end

  test "show should display bookmark button when not bookmarked" do
    get article_path(@article)

    assert_response :success
    assert_select "button", text: "Add to Reading List"
  end

  test "show should display unbookmark button when bookmarked" do
    @article.bookmark!
    get article_path(@article)

    assert_response :success
    assert_select "button", text: "Remove from Reading List"
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

    assert_redirected_to articles_path
    assert_equal "Article not found.", flash[:alert]
  end

  test "should handle undismiss with missing article" do
    delete undismiss_article_path(99999)

    assert_redirected_to articles_path
    assert_equal "Article not found.", flash[:alert]
  end

  test "should exclude permanently dismissed articles from index" do
    @article.dismiss!
    @article.dismissed_article.update!(permanent: true)

    get articles_path

    assert_response :success
    assert_select "h2", text: @article.title, count: 0
  end

  test "should include temporarily dismissed articles in index" do
    @article.dismiss!

    get articles_path

    assert_response :success
    assert_select "h2", text: @article.title, count: 1
  end

  test "index should return JSON with articles" do
    get articles_url, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert json_response.key?("articles")
    assert json_response.key?("pagination")
    assert json_response.key?("categories")
    assert json_response.key?("articles_by_category")
    assert json_response.key?("last_updated")

    assert json_response["articles"].is_a?(Array)
    assert json_response["pagination"]["current_page"] == 1
    assert json_response["pagination"]["per_page"] == 50
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
