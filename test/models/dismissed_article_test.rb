require "test_helper"

class DismissedArticleTest < ActiveSupport::TestCase
  def setup
    @article = articles(:hacker_news_article)
    @dismissed_article = @article.dismiss!
    @dismissed_article.update!(permanent: true)
  end

  test "should belong to article" do
    assert_respond_to @dismissed_article, :article
    assert_equal @article, @dismissed_article.article
  end

  test "should validate presence of dismissed_at" do
    dismissed = DismissedArticle.new(article: @article)
    assert_not dismissed.valid?
    assert_includes dismissed.errors[:dismissed_at], "can't be blank"
  end

  test "should validate uniqueness of article_id" do
    duplicate = DismissedArticle.new(
      article: @dismissed_article.article,
      dismissed_at: Time.current
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:article_id], "has already been taken"
  end

  test "should have default permanent value of false" do
    dismissed = DismissedArticle.create!(
      article: articles(:dev_to_article),
      dismissed_at: Time.current
    )
    assert_not dismissed.permanent?
  end

  test "should scope temporary dismissed articles" do
    temporary_dismissed = DismissedArticle.create!(
      article: articles(:dev_to_article),
      dismissed_at: Time.current,
      permanent: false
    )
    
    assert_includes DismissedArticle.temporary, temporary_dismissed
    assert_not_includes DismissedArticle.temporary, @dismissed_article
  end

  test "should scope permanent dismissed articles" do
    @dismissed_article.update!(permanent: true)
    
    assert_includes DismissedArticle.permanent, @dismissed_article
    assert_not_includes DismissedArticle.permanent, DismissedArticle.temporary.first
  end

  test "should create dismissed article with valid attributes" do
    dismissed = DismissedArticle.create!(
      article: articles(:dev_to_article),
      dismissed_at: Time.current
    )
    
    assert dismissed.persisted?
    assert_not dismissed.permanent?
    assert dismissed.dismissed_at.present?
  end

  test "should update permanent status" do
    dismissed = DismissedArticle.create!(
      article: articles(:dev_to_article),
      dismissed_at: Time.current,
      permanent: false
    )
    
    dismissed.update!(permanent: true)
    assert dismissed.permanent?
  end
end
