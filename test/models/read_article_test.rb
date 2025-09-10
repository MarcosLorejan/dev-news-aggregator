require "test_helper"

class ReadArticleTest < ActiveSupport::TestCase
  def setup
    @article = articles(:hacker_news_article)
    @read_article = ReadArticle.new(article: @article)
  end

  test "should be valid with valid attributes" do
    assert @read_article.valid?
  end

  test "should require article" do
    @read_article.article = nil
    assert_not @read_article.valid?
    assert_includes @read_article.errors[:article], "must exist"
  end

  test "should belong to article" do
    assert_respond_to @read_article, :article
    assert_instance_of Article, @read_article.article
  end

  test "should validate uniqueness of article_id" do
    @read_article.save!
    duplicate = ReadArticle.new(article: @article)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:article_id], "has already been taken"
  end

  test "should set read_at before create" do
    @read_article.save!
    assert @read_article.read_at.present?
    assert @read_article.read_at <= Time.current
  end

  test "should not override manually set read_at" do
    custom_time = 2.days.ago
    @read_article.read_at = custom_time
    @read_article.save!
    assert_in_delta custom_time.to_f, @read_article.read_at.to_f, 1.0
  end

  test "should destroy read_article when article is destroyed" do
    @read_article.save!
    assert_difference "ReadArticle.count", -1 do
      @article.destroy
    end
  end

  test "should order recent scope by read_at desc" do
    older_read = ReadArticle.create!(article: articles(:dev_to_article), read_at: 2.days.ago)
    newer_read = ReadArticle.create!(article: articles(:reddit_rust_article), read_at: 1.day.ago)
    
    recent_reads = ReadArticle.recent
    assert_equal newer_read, recent_reads.first
    assert_equal older_read, recent_reads.last
  end
end
