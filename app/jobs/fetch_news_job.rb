class FetchNewsJob < ApplicationJob
  queue_as :default

  def perform
    result = NewsAggregatorService.fetch_all_news
    YoutubeKeywordDiscovery.run!
    YoutubeVideoEnricher.enrich!
    result
  end
end
