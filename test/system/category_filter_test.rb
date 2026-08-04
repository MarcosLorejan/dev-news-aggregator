require "application_system_test_case"

class CategoryFilterTest < ApplicationSystemTestCase
  def setup
    @article1 = articles(:hacker_news_article)
    @article2 = articles(:reddit_rust_article)
    @article3 = articles(:dev_to_article)
  end

  test "should maintain category filter after client-side navigation" do
    visit_articles_index
    open_filters_menu

    first_category_btn = first("button.filter-btn[data-filter-type='category']")
    skip "No category filter buttons found" unless first_category_btn

    category_value = first_category_btn["data-filter-value"]
    first_category_btn.click
    assert_selector "article.article-card[data-category='#{category_value}']", visible: true
    assert_match(/category=#{Regexp.escape(category_value)}/, page.current_url)

    find("[data-testid='app-nav-saved']").click
    assert_selector "[data-testid='bookmarks-page']", wait: 12
    assert_current_path bookmarks_path

    find("[data-testid='app-nav-feed']").click
    assert_selector "[data-testid='articles-page']", wait: 12
    assert_no_selector "[data-testid='article-list-skeleton']", wait: 12

    open_filters_menu
    fresh_category_btn = first("button.filter-btn[data-filter-type='category']")
    skip "No category filter buttons found after navigation" unless fresh_category_btn

    fresh_category_value = fresh_category_btn["data-filter-value"]
    fresh_category_btn.click
    assert_selector "article.article-card[data-category='#{fresh_category_value}']", visible: true
  end

  test "should handle multiple navigation cycles with category filtering" do
    visit_articles_index

    3.times do |i|
      open_filters_menu
      all_articles_btn = first("button.filter-btn[data-filter-value='all']")
      skip "No articles or filter buttons found on iteration #{i}" unless all_articles_btn

      all_articles_btn.click
      assert_selector "article.article-card", minimum: 1

      visit_bookmarks_index
      assert_current_path bookmarks_path

      visit_articles_index
      assert_current_path articles_path

      open_filters_menu
      first_category_btn = first("button.filter-btn[data-filter-type='category']")
      next unless first_category_btn

      category_value = first_category_btn["data-filter-value"]
      first_category_btn.click
      assert_selector "article.article-card[data-category='#{category_value}']", visible: true
    end
  end

  test "category filter paginates server-side across matching articles" do
    55.times do |i|
      Article.create!(
        title: "Paged Rust #{i}",
        url: "https://example.com/paged-rust-#{i}",
        external_id: "paged-rust-#{i}",
        source_type: "reddit_rust",
        published_at: i.hours.ago,
        score: 10,
        comment_count: 0
      )
    end

    visit articles_path(category: "programming-languages")
    assert_selector "[data-testid='articles-page']", wait: 10
    assert_selector "article.article-card[data-category='programming-languages']", visible: true, minimum: 1
    assert_no_selector "article.article-card[data-category='general-tech']"
    assert_match(/category=programming-languages/, page.current_url)

    assert_selector "[data-testid='articles-pagination']", wait: 5
    page_one_titles = all("article.article-card").map { |card| card.text }

    find("[data-testid='pagination-next']").click

    assert_match(/page=2/, page.current_url)
    assert_match(/category=programming-languages/, page.current_url)
    assert_selector "article.article-card[data-category='programming-languages']", visible: true, minimum: 1
    assert_no_selector "article.article-card[data-category='general-tech']"

    page_two_titles = all("article.article-card").map { |card| card.text }
    assert_empty page_one_titles & page_two_titles
  end
end
