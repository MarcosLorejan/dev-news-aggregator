require "test_helper"

class DigestsControllerTest < ActionDispatch::IntegrationTest
  test "index JSON lists digests newest first" do
    older = NewsDigest.create!(
      period: "daily",
      window_start: 2.days.ago,
      window_end: 1.day.ago,
      payload: {
        "period" => "daily",
        "generated_at" => Time.current.iso8601,
        "window_start" => 2.days.ago.iso8601,
        "window_end" => 1.day.ago.iso8601,
        "themes" => [],
        "articles" => []
      }
    )
    newer = DigestBuilder.build!(period: "daily")

    get digests_url, as: :json
    assert_response :success

    ids = JSON.parse(response.body)["digests"].map { |row| row["id"] }
    assert_equal newer.id, ids.first
    assert_includes ids, older.id
  end

  test "create JSON builds a digest" do
    articles(:hacker_news_article).update!(published_at: 1.hour.ago)

    assert_difference "NewsDigest.count", 1 do
      post digests_url, params: { period: "daily" }, as: :json
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "daily", body["period"]
    assert body["payload"]["articles"].is_a?(Array)
  end

  test "show JSON returns digest payload" do
    digest = DigestBuilder.build!(period: "weekly")
    get digest_url(digest), as: :json
    assert_response :success
    assert_equal digest.id, JSON.parse(response.body)["id"]
  end
end
