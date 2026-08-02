require "test_helper"

class ArticleClustererTest < ActiveSupport::TestCase
  setup do
    @hn = articles(:hacker_news_article)
    @dev_to = articles(:dev_to_article)
  end

  test "primaries keep highest score article per canonical url" do
    shared = "https://example.com/shared-story"
    @hn.update!(url: "#{shared}?utm_source=hn", score: 50)
    @dev_to.update!(url: "#{shared}?utm_campaign=devto", score: 200)

    ids = ArticleClusterer.primaries(Article.all).pluck(:id)
    assert_includes ids, @dev_to.id
    assert_not_includes ids, @hn.id
  end

  test "related_by_article_id returns sibling sources" do
    shared = "https://example.com/clustered"
    @hn.update!(url: shared, score: 10)
    @dev_to.update!(url: "#{shared}/", score: 5)

    related = ArticleClusterer.related_by_article_id([ @hn ])
    assert_equal 1, related[@hn.id].length
    assert_equal @dev_to.id, related[@hn.id].first.id
  end

  test "articles without shared urls remain unique primaries" do
    ids = ArticleClusterer.primaries(Article.all).pluck(:id)
    assert_equal Article.count, ids.length
  end
end
