require "test_helper"

class KeywordFiltersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @ruby_interest = keyword_filters(:ruby_interest)
  end

  test "index returns filters with terms and match counts" do
    get keyword_filters_url, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    names = body["keyword_filters"].map { |filter| filter["name"] }
    assert_includes names, "Ruby"
    assert_includes names, "Elixir"

    ruby = body["keyword_filters"].find { |filter| filter["slug"] == "ruby" }
    assert_equal [ "ruby", "rubygems" ], ruby["terms"]
    assert_equal 1, ruby["article_count"]

    elixir = body["keyword_filters"].find { |filter| filter["slug"] == "elixir" }
    assert_equal 0, elixir["article_count"]
  end

  test "index seeds default interests when none exist" do
    KeywordFilter.delete_all

    get keyword_filters_url, as: :json
    assert_response :success

    slugs = JSON.parse(response.body)["keyword_filters"].map { |filter| filter["slug"] }
    assert_includes slugs, "software-architecture"
  end

  test "index counts matches in a single query per request" do
    queries = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      queries += 1 if payload[:sql].to_s.include?("keyword_count_0")
    end

    get keyword_filters_url, as: :json

    assert_equal 1, queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  test "create adds a filter from an array of terms" do
    assert_difference -> { KeywordFilter.count }, 1 do
      post keyword_filters_url, params: { keyword_filter: { name: "Observability", terms: [ "tracing", " OpenTelemetry " ] } }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "observability", body["slug"]
    assert_equal [ "tracing", "opentelemetry" ], body["terms"]
  end

  test "create accepts comma-separated terms" do
    post keyword_filters_url, params: { keyword_filter: { name: "Databases", terms: "postgres, sqlite" } }, as: :json

    assert_response :created
    assert_equal [ "postgres", "sqlite" ], JSON.parse(response.body)["terms"]
  end

  test "create returns 422 with messages for invalid payloads" do
    assert_no_difference -> { KeywordFilter.count } do
      post keyword_filters_url, params: { keyword_filter: { name: "", terms: [] } }, as: :json
    end

    assert_response :unprocessable_entity
    errors = JSON.parse(response.body)["errors"]
    assert_includes errors, "Name can't be blank"
    assert_includes errors, "Terms must include at least one keyword"
  end

  test "update replaces terms and toggles active" do
    patch keyword_filter_url(@ruby_interest), params: { keyword_filter: { terms: [ "ruby", "hotwire" ], active: false } }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [ "ruby", "hotwire" ], body["terms"]
    assert_equal false, body["active"]
  end

  test "update returns 422 when terms become empty" do
    patch keyword_filter_url(@ruby_interest), params: { keyword_filter: { terms: [ "  " ] } }, as: :json

    assert_response :unprocessable_entity
    assert_equal [ "ruby", "rubygems" ], @ruby_interest.reload.terms
  end

  test "destroy removes the filter" do
    assert_difference -> { KeywordFilter.count }, -1 do
      delete keyword_filter_url(@ruby_interest)
    end

    assert_response :no_content
  end

  test "update returns 404 for unknown filters" do
    patch keyword_filter_url(id: 0), params: { keyword_filter: { name: "Nope" } }, as: :json

    assert_response :not_found
  end

  test "writes require mutating auth when configured" do
    previous_username = ENV["MUTATING_AUTH_USERNAME"]
    previous_password = ENV["MUTATING_AUTH_PASSWORD"]
    ENV["MUTATING_AUTH_USERNAME"] = "admin"
    ENV["MUTATING_AUTH_PASSWORD"] = "secret"

    post keyword_filters_url, params: { keyword_filter: { name: "Blocked", terms: [ "nope" ] } }, as: :json
    assert_response :unauthorized

    get keyword_filters_url, as: :json
    assert_response :success

    post keyword_filters_url,
         params: { keyword_filter: { name: "Allowed", terms: [ "yes" ] } },
         headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret") },
         as: :json
    assert_response :created
  ensure
    if previous_username
      ENV["MUTATING_AUTH_USERNAME"] = previous_username
    else
      ENV.delete("MUTATING_AUTH_USERNAME")
    end

    if previous_password
      ENV["MUTATING_AUTH_PASSWORD"] = previous_password
    else
      ENV.delete("MUTATING_AUTH_PASSWORD")
    end
  end
end
