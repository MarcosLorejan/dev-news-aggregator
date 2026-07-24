require "test_helper"

class MutatingAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:hacker_news_article)
    @previous_username = ENV["MUTATING_AUTH_USERNAME"]
    @previous_password = ENV["MUTATING_AUTH_PASSWORD"]
    ENV["MUTATING_AUTH_USERNAME"] = "admin"
    ENV["MUTATING_AUTH_PASSWORD"] = "secret"
  end

  teardown do
    if @previous_username
      ENV["MUTATING_AUTH_USERNAME"] = @previous_username
    else
      ENV.delete("MUTATING_AUTH_USERNAME")
    end

    if @previous_password
      ENV["MUTATING_AUTH_PASSWORD"] = @previous_password
    else
      ENV.delete("MUTATING_AUTH_PASSWORD")
    end
  end

  test "should reject unauthenticated mutating requests with 401 JSON" do
    post bookmark_article_url(@article), as: :json

    assert_response :unauthorized
    assert_equal "Unauthorized", JSON.parse(response.body)["error"]
    assert_includes response.headers["WWW-Authenticate"].to_s, "Basic"
  end

  test "should reject mutating requests with invalid credentials" do
    post bookmark_article_url(@article),
         headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "wrong") },
         as: :json

    assert_response :unauthorized
  end

  test "should allow mutating requests with valid credentials" do
    post bookmark_article_url(@article),
         headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret") },
         as: :json

    assert_response :success
    assert JSON.parse(response.body)["bookmarked"]
  end

  test "should leave read endpoints public when mutating auth is enabled" do
    get articles_url, as: :json
    assert_response :success

    get sources_url, as: :json
    assert_response :success
  end

  test "should allow mutations without credentials when auth is not configured" do
    ENV.delete("MUTATING_AUTH_USERNAME")
    ENV.delete("MUTATING_AUTH_PASSWORD")

    post bookmark_article_url(@article), as: :json
    assert_response :success
  end
end
