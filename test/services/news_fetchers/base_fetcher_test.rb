require "test_helper"

class NewsFetchers::BaseFetcherTest < ActiveSupport::TestCase
  def setup
    @fetcher = NewsFetchers::BaseFetcher.new
  end

  test "should initialize with empty articles array" do
    assert_equal [], @fetcher.instance_variable_get(:@articles)
  end

  test "fetch_articles should raise NotImplementedError" do
    assert_raises NotImplementedError do
      @fetcher.fetch_articles
    end
  end

  test "should create new article with valid attributes" do
    attributes = {
      title: "Test Article",
      url: "https://example.com",
      published_at: Time.current,
      description: "Test description",
      external_id: "test123",
      source_type: "test_source",
      score: 100,
      comment_count: 10
    }

    assert_difference "Article.count", 1 do
      article = @fetcher.instance_eval { create_or_update_article(attributes) }
      assert_kind_of Article, article
      assert_equal "Test Article", article.title
      assert_equal "test_source", article.source_type
    end
  end

  test "should update existing article with same external_id and source_type" do
    # Create an existing article
    existing_article = Article.create!(
      title: "Old Title",
      url: "https://example.com",
      published_at: 1.day.ago,
      description: "Old description",
      external_id: "test123",
      source_type: "test_source",
      score: 50,
      comment_count: 5
    )

    # Update attributes
    attributes = {
      title: "Updated Title",
      url: "https://example.com",
      published_at: Time.current,
      description: "Updated description",
      external_id: "test123",
      source_type: "test_source",
      score: 100,
      comment_count: 10
    }

    assert_no_difference "Article.count" do
      article = @fetcher.instance_eval { create_or_update_article(attributes) }
      assert_equal existing_article.id, article.id
      assert_equal "Updated Title", article.title
      assert_equal 100, article.score
    end
  end

  test "should not update article when no changes detected" do
    attributes = {
      title: "Test Article",
      url: "https://example.com",
      published_at: Time.current,
      description: "Test description",
      external_id: "test123",
      source_type: "test_source",
      score: 100,
      comment_count: 10
    }

    article = @fetcher.instance_eval { create_or_update_article(attributes) }
    updated_article = @fetcher.instance_eval { create_or_update_article(attributes) }

    assert_equal article.id, updated_article.id
    assert_equal article.updated_at.to_i, updated_article.updated_at.to_i
  end
end
