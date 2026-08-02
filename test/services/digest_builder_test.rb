require "test_helper"

class DigestBuilderTest < ActiveSupport::TestCase
  setup do
    @hn = articles(:hacker_news_article)
    @dev_to = articles(:dev_to_article)
    travel_to Time.zone.parse("2024-06-15 12:00:00 UTC")
  end

  teardown do
    travel_back
  end

  test "builds schema-validated daily digest from unread articles in window" do
    @hn.update!(published_at: 12.hours.ago, score: 200)
    @dev_to.update!(published_at: 12.hours.ago, score: 50)

    digest = DigestBuilder.build!(period: "daily", at: Time.current)

    assert_equal "daily", digest.period
    payload = digest.payload
    assert_equal "daily", payload["period"]
    assert payload["themes"].is_a?(Array)
    assert payload["articles"].is_a?(Array)
    ids = payload["articles"].map { |row| row["id"] }
    assert_includes ids, @hn.id
    assert_includes ids, @dev_to.id
  end

  test "excludes read and permanently dismissed articles" do
    @hn.update!(published_at: 12.hours.ago)
    @dev_to.update!(published_at: 12.hours.ago)
    @hn.mark_as_read!
    DismissedArticle.create!(article: @dev_to, dismissed_at: Time.current, permanent: true)

    digest = DigestBuilder.build!(period: "daily", at: Time.current)
    ids = digest.payload["articles"].map { |row| row["id"] }
    assert_not_includes ids, @hn.id
    assert_not_includes ids, @dev_to.id
  end

  test "validate_payload! rejects unknown keys" do
    builder = DigestBuilder.new(period: "daily", at: Time.current)
    assert_raises(ArgumentError) do
      builder.send(:validate_payload!, { "period" => "daily", "extra" => true })
    end
  end
end
