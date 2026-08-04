require "application_system_test_case"

class BookmarkFunctionalityTest < ApplicationSystemTestCase
  def setup
    @article = articles(:hacker_news_article)
    @bookmarked_article = articles(:reddit_rust_article)
    @article.unbookmark! if @article.bookmarked?
    @bookmarked_article.bookmark! unless @bookmarked_article.bookmarked?
  end

  test "should bookmark article from index page" do
    visit_articles_index

    within("[data-source='#{@article.source_type}']") do
      bookmark_button = find("button[title='Add to reading list']")
      bookmark_button.click
    end

    sleep 0.5
    assert @article.reload.bookmarked?
  end

  test "should unbookmark article from index page" do
    visit_articles_index

    within("[data-source='#{@bookmarked_article.source_type}']") do
      unbookmark_button = find("button[title='Remove from reading list']")
      unbookmark_button.click
    end

    sleep 0.5
    assert_not @bookmarked_article.reload.bookmarked?
  end

  test "should navigate to reading list" do
    visit_articles_index

    click_link "Reading List"

    assert_current_path bookmarks_path
    assert_selector "h1", text: "Reading List"
  end

  test "should show bookmarked articles in reading list" do
    visit_bookmarks_index

    assert_selector "article.article-card[data-source='reddit_rust']"
    assert_selector "article.article-card[data-source='reddit_ruby']"
    within("article.article-card[data-source='reddit_rust']") do
      assert_text @bookmarked_article.title
      assert_selector "span", text: /Bookmarked/
    end
  end

  test "should filter articles by category" do
    visit_articles_index
    open_filters_menu

    category_btn = first("button.filter-btn[data-filter-type='category'][data-filter-value='programming-languages']")
    if category_btn
      category_btn.click
      assert_selector "article.article-card[data-category='programming-languages']", visible: true
    else
      skip "No Programming Languages category found"
    end
  end

  test "should show all articles when clicking All Articles filter" do
    visit_articles_index
    open_filters_menu

    category_btn = first("button.filter-btn[data-filter-type='category'][data-filter-value='programming-languages']")
    category_btn&.click

    open_filters_menu unless page.has_selector?("button[data-filter-value='all']", wait: 1)
    find("button[data-filter-value='all']").click

    assert_selector "article.article-card", minimum: 1
  end

  test "should filter by specific category" do
    visit_articles_index
    open_filters_menu

    first_category_btn = first("button.filter-btn[data-filter-type='category']")
    if first_category_btn
      category_value = first_category_btn["data-filter-value"]
      first_category_btn.click
      assert_selector "article.article-card[data-category='#{category_value}']", visible: true
    else
      skip "No category filter buttons found"
    end
  end

  test "should bookmark article from detail page" do
    visit_article_show(@article)

    if page.has_button?("Add to Reading List")
      click_button "Add to Reading List"
      sleep 0.5
      assert @article.reload.bookmarked?
    else
      skip "Article is already bookmarked or bookmark button not found"
    end
  end

  test "should unbookmark article from detail page" do
    visit_article_show(@bookmarked_article)

    if page.has_button?("Remove from Reading List")
      click_button "Remove from Reading List"
      find("[data-testid='confirm-dialog-confirm']").click
      sleep 0.5
      assert_not @bookmarked_article.reload.bookmarked?
    else
      skip "Article is not bookmarked or unbookmark button not found"
    end
  end

  test "should remove bookmark from reading list" do
    visit_bookmarks_index

    if page.has_selector?("article.article-card[data-source='reddit_rust']")
      within("article.article-card[data-source='reddit_rust']") do
        find("button[title='Remove from reading list']").click
      end
      find("[data-testid='confirm-dialog-confirm']").click
      assert_no_selector "article.article-card[data-source='reddit_rust']", wait: 10
      assert_not @bookmarked_article.reload.bookmarked?
    else
      skip "No bookmarked Reddit Rust articles found"
    end
  end

  test "should show empty state when no bookmarks exist" do
    Bookmark.destroy_all

    visit_bookmarks_index

    assert_selector "h2", text: "No bookmarked articles yet"
    assert_selector "p", text: "Articles you bookmark will appear here in your reading list."
    assert_link "Browse Articles", href: articles_path
  end

  test "should navigate between articles and reading list" do
    visit_articles_index

    click_link "Reading List"
    assert_current_path bookmarks_path

    click_link "Feed", match: :first
    assert_current_path root_path
  end
end
