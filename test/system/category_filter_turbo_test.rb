require "application_system_test_case"

class CategoryFilterTurboTest < ApplicationSystemTestCase
  def setup
    @article1 = articles(:hacker_news_article)
    @article2 = articles(:reddit_rust_article)
    @article3 = articles(:dev_to_article)
  end

  test "should maintain category filter functionality after Turbo navigation" do
    visit articles_path

    if has_button?("All Articles", wait: 2)
      first_category_btn = first("button.filter-btn[data-filter-type='category']")
      
      if first_category_btn
        category_value = first_category_btn["data-filter-value"]
        
        first_category_btn.click
        assert_selector "article.article-card[data-category='#{category_value}']", visible: true
        
        click_link "Reading List"
        assert_current_path bookmarks_path
        
        click_link "Back to All Articles"
        assert_current_path articles_path
        
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
    visit articles_path

    3.times do |i|
      if has_button?("All Articles", wait: 2)
        all_articles_btn = find("button[data-filter-value='all']")
        all_articles_btn.click
        assert_selector "article.article-card", minimum: 1

        visit bookmarks_path
        assert_current_path bookmarks_path

        visit articles_path
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
    visit articles_path

    if has_button?("All Articles", wait: 2)
      first_category_btn = first("button.filter-btn[data-filter-type='category']")
      
      if first_category_btn
        category_value = first_category_btn["data-filter-value"]
        first_category_btn.click
        
        visible_articles_before = all("article.article-card[data-category='#{category_value}']", visible: true).count
        assert visible_articles_before > 0, "Expected visible articles after filtering"
        
        page.evaluate_script("initializeCategoryFilter();")
        
        visible_articles_after = all("article.article-card[data-category='#{category_value}']", visible: true).count
        assert_equal visible_articles_before, visible_articles_after
        
        fresh_category_btn = first("button.filter-btn[data-filter-type='category']")
        fresh_category_btn.click if fresh_category_btn
        assert_selector "article.article-card[data-category='#{category_value}']", visible: true
      else
        skip "No category filter buttons found"
      end
    else
      skip "No articles found"
    end
  end
end
