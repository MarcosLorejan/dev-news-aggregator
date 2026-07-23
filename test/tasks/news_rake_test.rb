require "test_helper"
require "rake"
require "active_job/test_helper"

class NewsRakeTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  def setup
    Rails.application.load_tasks
    @article = articles(:hacker_news_article)
    @article.update!(published_at: 10.days.ago)
    @article.bookmark!
  end

  test "news:fetch_status reports recorded fetch outcomes" do
    FetchRun.record_outcome(
      source_key: "hacker_news",
      status: "success",
      articles_count: 2,
      duration_seconds: 1.0
    )

    output = capture_io do
      Rake::Task["news:fetch_status"].invoke
    end

    assert_match(/hacker_news: success \(2 articles/, output.join)
  ensure
    Rake::Task["news:fetch_status"].reenable
  end

  test "news:fetch enqueues FetchNewsJob instead of fetching synchronously" do
    assert_enqueued_with(job: FetchNewsJob) do
      capture_io do
        Rake::Task["news:fetch"].invoke
      end
    end
  ensure
    Rake::Task["news:fetch"].reenable
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

  test "news:clean removes multiple old articles and all dependents in batches" do
    retention_days = NewsAggregatorConfig.retention_days
    cutoff = (retention_days + 1).days.ago

    3.times do |i|
      article = Article.create!(
        title: "Old batch #{i}",
        url: "https://example.com/old-batch-#{i}",
        external_id: "old-batch-#{i}",
        source_type: "hacker_news",
        published_at: cutoff,
        score: 1,
        comment_count: 0
      )
      article.bookmark!
      article.mark_as_read!
    end

    # setup already has one old bookmarked article; three more with bookmark + read.
    assert_difference "Article.count", -4 do
      assert_difference "Bookmark.count", -4 do
        assert_difference "ReadArticle.count", -3 do
          capture_io do
            Rake::Task["news:clean"].invoke
          end
        end
      end
    end

    assert_equal 0, Article.where("published_at < ?", retention_days.days.ago).count
  ensure
    Rake::Task["news:clean"].reenable
  end
end
