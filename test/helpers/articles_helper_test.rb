require "test_helper"

class ArticlesHelperTest < ActionView::TestCase
  def setup
    @articles_by_source = {
      "hacker_news" => [ articles(:hacker_news_article) ],
      "dev_to" => [ articles(:dev_to_article) ],
      "reddit_rust" => [ articles(:reddit_rust_article) ],
      "reddit_ruby" => [ articles(:reddit_ruby_article) ]
    }
  end

  test "should group sources by predefined categories" do
    grouped = group_sources_by_category(@articles_by_source)

    assert_includes grouped.keys, "Programming Languages"
    assert_includes grouped.keys, "General Tech"
    assert_includes grouped["Programming Languages"], articles(:reddit_rust_article)
    assert_includes grouped["Programming Languages"], articles(:reddit_ruby_article)
    assert_includes grouped["General Tech"], articles(:hacker_news_article)
    assert_includes grouped["General Tech"], articles(:dev_to_article)
  end

  test "should handle empty articles_by_source" do
    grouped = group_sources_by_category({})

    assert_kind_of Hash, grouped
    assert_empty grouped
  end

  test "should group unknown sources into Other category" do
    articles_with_unknown = @articles_by_source.merge(
      "unknown_source" => [ Article.new(title: "Test", source_type: "unknown_source") ]
    )

    grouped = group_sources_by_category(articles_with_unknown)

    assert_includes grouped.keys, "Other"
    assert_equal 1, grouped["Other"].length
  end

  test "should not create category for empty source arrays" do
    articles_by_source = {
      "hacker_news" => [ articles(:hacker_news_article) ],
      "reddit_empty" => []
    }

    grouped = group_sources_by_category(articles_by_source)

    assert_not_includes grouped.keys, "Programming Languages"
  end

  test "should return correct category icons" do
    assert_equal "🔨", category_icon("Programming Languages")
    assert_equal "🌐", category_icon("Web Development")
    assert_equal "🔒", category_icon("Security")
    assert_equal "🤖", category_icon("AI & Machine Learning")
    assert_equal "💻", category_icon("General Tech")
    assert_equal "📰", category_icon("Other")
  end

  test "should return default icon for unknown category" do
    assert_equal "📄", category_icon("Unknown Category")
  end

  test "should handle multiple articles in same category" do
    articles_by_source = {
      "reddit_rust" => [ articles(:reddit_rust_article) ],
      "reddit_ruby" => [ articles(:reddit_ruby_article) ],
      "reddit_javascript" => [ Article.new(title: "JS Test", source_type: "reddit_javascript") ]
    }

    grouped = group_sources_by_category(articles_by_source)

    assert_equal 3, grouped["Programming Languages"].length
  end

  test "category_slug matches frontend parameterization" do
    assert_equal "programming-languages", category_slug("Programming Languages")
    assert_equal "ai-&-machine-learning", category_slug("AI & Machine Learning")
  end

  test "source_types_for_category_slug resolves known categories" do
    assert_equal %w[reddit_ruby reddit_rust reddit_javascript],
                 source_types_for_category_slug("programming-languages")
    assert_equal :other, source_types_for_category_slug("other")
    assert_nil source_types_for_category_slug("all")
    assert_nil source_types_for_category_slug("unknown")
  end

  test "apply_category_filter restricts to matching source types" do
    scope = apply_category_filter(Article.all, "programming-languages")
    assert_includes scope, articles(:reddit_rust_article)
    assert_not_includes scope, articles(:hacker_news_article)
  end

  test "category_counts_for_scope aggregates across the full relation" do
    counts = category_counts_for_scope(Article.all)

    assert_equal 2, counts["Programming Languages"]
    assert_equal 2, counts["General Tech"]
  end
end
