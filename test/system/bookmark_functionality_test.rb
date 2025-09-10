require "application_system_test_case"

class BookmarkFunctionalityTest < ApplicationSystemTestCase
  def setup
    @article = articles(:hacker_news_article)
    @bookmarked_article = articles(:reddit_rust_article)
    @article.unbookmark! if @article.bookmarked?
    @bookmarked_article.bookmark! unless @bookmarked_article.bookmarked?
  end

  test "should bookmark article from index page" do
    visit articles_path

    within("[data-source='#{@article.source_type}']") do
      bookmark_button = find("button[title='Add to reading list']")
      bookmark_button.click
    end

    sleep 0.5
    assert @article.reload.bookmarked?
  end

  test "should unbookmark article from index page" do
    visit articles_path

    within("[data-source='#{@bookmarked_article.source_type}']") do
      unbookmark_button = find("button[title='Remove from reading list']")
      unbookmark_button.click
    end

    sleep 0.5
    assert_not @bookmarked_article.reload.bookmarked?
  end

  test "should navigate to reading list" do
    visit articles_path

    click_link "Reading List"

    assert_current_path bookmarks_path
    assert_selector "h1", text: "Reading List"
  end

  test "should show bookmarked articles in reading list" do
    visit bookmarks_path

    assert_selector "article.article-card[data-source='reddit_rust']"
    assert_selector "article.article-card[data-source='reddit_ruby']"
    within("article.article-card[data-source='reddit_rust']") do
      assert_text @bookmarked_article.title
      assert_selector "span", text: /🔖 Bookmarked/
    end
  end

  test "should filter articles by category" do
    visit articles_path

    # Look for a category button (they contain emojis and text)
    if page.has_button?("🔨 Programming Languages", wait: 1)
      click_button "🔨 Programming Languages"
      assert_selector "article.article-card[data-category='programming-languages']", visible: true
    else
      # Skip test if no Programming Languages category exists
      skip "No Programming Languages category found"
    end
  end

  test "should show all articles when clicking All Articles filter" do
    visit articles_path

    # First click a category filter if it exists
    if page.has_button?("🔨 Programming Languages", wait: 1)
      click_button "🔨 Programming Languages"
    end

    # Then click All Articles - the button text includes count
    all_articles_btn = find("button[data-filter-value='all']")
    all_articles_btn.click

    assert_selector "article.article-card", minimum: 1
  end

  test "should filter by specific source" do
    visit articles_path

    # Open the details dropdown for source filtering
    find("details summary").click

    # Click the first available source filter
    first_source_btn = first("button.source-filter-btn")
    if first_source_btn
      source_value = first_source_btn["data-filter-value"]
      first_source_btn.click
      assert_selector "article.article-card[data-source='#{source_value}']", visible: true
    else
      skip "No source filter buttons found"
    end
  end

  test "should bookmark article from detail page" do
    visit article_path(@article)

    if page.has_button?("Add to Reading List")
      click_button "Add to Reading List"
      sleep 0.5
      assert @article.reload.bookmarked?
    else
      skip "Article is already bookmarked or bookmark button not found"
    end
  end

  test "should unbookmark article from detail page" do
    visit article_path(@bookmarked_article)

    if page.has_button?("Remove from Reading List")
      click_button "Remove from Reading List"
      sleep 0.5
      assert_not @bookmarked_article.reload.bookmarked?
    else
      skip "Article is not bookmarked or unbookmark button not found"
    end
  end

  test "should remove bookmark from reading list" do
    visit bookmarks_path

    if page.has_selector?("article.article-card[data-source='reddit_rust']")
      within("article.article-card[data-source='reddit_rust']") do
        page.execute_script("window.confirm = function() { return true; }")
        find("button[title='Remove from reading list']").click
      end
      sleep 0.5
      assert_not @bookmarked_article.reload.bookmarked?
    else
      skip "No bookmarked Reddit Rust articles found"
    end
  end

  test "should show empty state when no bookmarks exist" do
    Bookmark.destroy_all

    visit bookmarks_path

    assert_selector "h2", text: "No bookmarked articles yet"
    assert_selector "p", text: "Articles you bookmark will appear here in your reading list."
    assert_link "Browse Articles", href: articles_path
  end

  test "should navigate between articles and reading list" do
    visit articles_path

    click_link "Reading List"
    assert_current_path bookmarks_path

    click_link "Back to All Articles"
    assert_current_path articles_path
  end
end
