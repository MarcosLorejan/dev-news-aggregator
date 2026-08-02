require "test_helper"

class FetchNewsJobTest < ActiveJob::TestCase
  test "perform delegates to NewsAggregatorService.fetch_all_news" do
    expected = {
      articles_count: 2,
      duration: 1.2,
      sources: [ "MockFetcher" ],
      timestamp: Time.current
    }

    original = NewsAggregatorService.method(:fetch_all_news)
    enrich_original = YoutubeVideoEnricher.method(:enrich!)
    NewsAggregatorService.define_singleton_method(:fetch_all_news) { expected }
    YoutubeVideoEnricher.define_singleton_method(:enrich!) { { enriched: 0, skipped: true } }
    begin
      result = FetchNewsJob.perform_now
      assert_equal expected, result
    ensure
      NewsAggregatorService.define_singleton_method(:fetch_all_news, original)
      YoutubeVideoEnricher.define_singleton_method(:enrich!, enrich_original)
    end
  end
end
