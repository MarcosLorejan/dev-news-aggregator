require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    @article = articles(:hacker_news_article)
  end

  test "should return 429 JSON when mutate throttle is exceeded" do
    limit = Rack::Attack::MUTATE_LIMIT

    limit.times do
      post bookmark_article_url(@article), as: :json
      assert_response :success
    end

    post bookmark_article_url(@article), as: :json
    assert_response :too_many_requests
    assert_equal "application/json", response.media_type
    assert_equal "Rate limit exceeded. Please try again later.", JSON.parse(response.body)["error"]
    assert response.headers["Retry-After"].present?
  end

  test "should not throttle health check endpoint" do
    (Rack::Attack::MUTATE_LIMIT + 2).times do
      get rails_health_check_url
      assert_response :success
    end
  end

  test "should allow normal read traffic under global limit" do
    3.times do
      get articles_url, as: :json
      assert_response :success
    end
  end
end
