class FetchNewsJob < ApplicationJob
  queue_as :default

  def perform
    NewsAggregatorService.fetch_all_news
  end
end
