require "test_helper"

class MakeDismissalPermanentJobTest < ActiveJob::TestCase
  def setup
    @article = articles(:hacker_news_article)
    @dismissed_article = @article.dismiss!
  end

  test "should make dismissal permanent" do
    assert_not @dismissed_article.permanent?
    
    MakeDismissalPermanentJob.perform_now(@dismissed_article.id)
    
    assert @dismissed_article.reload.permanent?
  end

  test "should handle non-existent dismissed article gracefully" do
    assert_nothing_raised do
      MakeDismissalPermanentJob.perform_now(99999)
    end
  end

  test "should not update already permanent dismissal" do
    @dismissed_article.update!(permanent: true)
    original_updated_at = @dismissed_article.updated_at
    
    MakeDismissalPermanentJob.perform_now(@dismissed_article.id)
    
    assert @dismissed_article.reload.permanent?
    assert_equal original_updated_at.to_i, @dismissed_article.updated_at.to_i
  end

  test "should only update permanent field" do
    original_dismissed_at = @dismissed_article.dismissed_at
    
    MakeDismissalPermanentJob.perform_now(@dismissed_article.id)
    
    @dismissed_article.reload
    assert @dismissed_article.permanent?
    assert_equal original_dismissed_at.to_i, @dismissed_article.dismissed_at.to_i
  end
end
