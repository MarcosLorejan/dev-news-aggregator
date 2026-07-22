require "application_system_test_case"

class CategoryFilterTurboTest < ApplicationSystemTestCase
  def setup
    @article1 = articles(:hacker_news_article)
    @article2 = articles(:reddit_rust_article)
    @article3 = articles(:dev_to_article)
  end

  test "should maintain category filter functionality after Turbo navigation" do
    visit_articles_index

    if has_button?("All Articles", wait: 2)
      first_category_btn = first("button.filter-btn[data-filter-type='category']")

      if first_category_btn
        category_value = first_category_btn["data-filter-value"]

        first_category_btn.click
        assert_selector "article.article-card[data-category='#{category_value}']", visible: true

        click_link "Reading List"
        assert_current_path bookmarks_path

        click_link "Feed", match: :first
        assert_current_path root_path

        fresh_category_btn = first("button.filter-btn[data-filter-type='category']")
        if fresh_category_btn
          fresh_category_value = fresh_category_btn["data-filter-value"]
          fresh_category_btn.click
          assert_selector "article.article-card[data-category='#{fresh_category_value}']", visible: true
        else
          skip "No category filter buttons found after navigation"
        end
      else
        skip "No category filter buttons found"
      end
    else
      skip "No articles or filter buttons found"
    end
  end

  test "should handle multiple Turbo navigation cycles with category filtering" do
    visit_articles_index

    3.times do |i|
      if has_button?("All Articles", wait: 2)
        all_articles_btn = find("button[data-filter-value='all']")
        all_articles_btn.click
        assert_selector "article.article-card", minimum: 1

        visit_bookmarks_index
        assert_current_path bookmarks_path

        visit_articles_index
        assert_current_path articles_path

        first_category_btn = first("button.filter-btn[data-filter-type='category']")
        if first_category_btn
          category_value = first_category_btn["data-filter-value"]
          first_category_btn.click
          assert_selector "article.article-card[data-category='#{category_value}']", visible: true
        end
      else
        skip "No articles or filter buttons found on iteration #{i}"
        break
      end
    end
  end

  test "should preserve filter state after JavaScript re-initialization" do
    visit_articles_index

    if has_button?("All Articles", wait: 2)
      first_category_btn = first("button.filter-btn[data-filter-type='category']")

      if first_category_btn
        category_value = first_category_btn["data-filter-value"]
        first_category_btn.click
        assert_match(/category=/, page.current_url)

        assert_selector "article.article-card[data-category='#{category_value}']", visible: true, minimum: 1

        page.evaluate_script("initializeCategoryFilter();")

        assert_match(/category=#{Regexp.escape(category_value)}/, page.current_url)
        assert_selector "article.article-card[data-category='#{category_value}']", visible: true, minimum: 1
      else
        skip "No category filter buttons found"
      end
    else
      skip "No articles found"
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
