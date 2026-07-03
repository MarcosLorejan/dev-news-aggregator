require "test_helper"
require "rake"

class NewsRakeTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_tasks
    @article = articles(:hacker_news_article)
    @article.update!(published_at: 10.days.ago)
    @article.bookmark!
  end

  test "news:clean removes old articles and dependent records" do
    assert_difference "Article.count", -1 do
      assert_difference "Bookmark.count", -1 do
        capture_io do
          Rake::Task["news:clean"].invoke
        end
      end
    end
  ensure
    Rake::Task["news:clean"].reenable
  end
end
