require "application_system_test_case"

class ReadArticlesFunctionalityTest < ApplicationSystemTestCase
  def setup
    @article = articles(:hacker_news_article)
    @bookmarked_article = articles(:reddit_rust_article)
    @read_article = articles(:dev_to_article)

    # Set up initial states
    @article.unbookmark! if @article.bookmarked?
    @article.unmark_as_read! if @article.read?

    @bookmarked_article.bookmark! unless @bookmarked_article.bookmarked?
    @bookmarked_article.unmark_as_read! if @bookmarked_article.read?

    @read_article.mark_as_read! unless @read_article.read?
  end

  test "should mark article as read from bookmark page" do
    visit_bookmarks_index

    within("article.article-card[data-source='#{@bookmarked_article.source_type}']") do
      read_button = find("button[title='Mark as read']")
      read_button.click
    end

    sleep 0.5
    assert @bookmarked_article.reload.read?
  end

  test "should mark article as unread from bookmark page" do
    @bookmarked_article.mark_as_read!
    visit_bookmarks_index

    within("article.article-card[data-source='#{@bookmarked_article.source_type}']") do
      unread_button = find("button[title='Mark as unread']")
      unread_button.click
    end

    sleep 0.5
    assert_not @bookmarked_article.reload.read?
  end

  test "should mark article as read from article detail page" do
    visit_article_show(@article)

    click_button "Mark as Read"

    sleep 0.5
    assert @article.reload.read?
  end

  test "should mark article as unread from article detail page" do
    @article.mark_as_read!
    visit_article_show(@article)

    click_button "Mark as Unread"

    sleep 0.5
    assert_not @article.reload.read?
  end

  test "should show read status indicator on article detail page" do
    @article.mark_as_read!
    visit_article_show(@article)

    assert_selector "span", text: "Already Read"
    within(find("span", text: "Already Read")) do
      assert_selector "svg", count: 1
    end
  end

  test "should show correct button state on article detail page for read article" do
    @article.mark_as_read!
    visit_article_show(@article)

    assert_button "Mark as Unread"
    assert_no_button "Mark as Read"
  end

  test "should show correct button state on article detail page for unread article" do
    visit_article_show(@article)

    assert_button "Mark as Read"
    assert_no_button "Mark as Unread"
  end

  test "should show correct button state on bookmark page for read article" do
    @bookmarked_article.mark_as_read!
    visit_bookmarks_index

    within("article.article-card[data-source='#{@bookmarked_article.source_type}']") do
      assert_selector "button[title='Mark as unread']"
      assert_no_selector "button[title='Mark as read']"
    end
  end

  test "should show correct button state on bookmark page for unread article" do
    visit_bookmarks_index

    within("article.article-card[data-source='#{@bookmarked_article.source_type}']") do
      assert_selector "button[title='Mark as read']"
      assert_no_selector "button[title='Mark as unread']"
    end
  end

  test "should maintain bookmark status when marking as read from bookmark page" do
    visit_bookmarks_index

    within("article.article-card[data-source='#{@bookmarked_article.source_type}']") do
      find("button[title='Mark as read']").click
    end

    sleep 0.5
    assert @bookmarked_article.reload.read?
    assert @bookmarked_article.reload.bookmarked?
  end

  test "should navigate to already read section" do
    visit_articles_index

    click_link "Already Read"

    assert_current_path read_articles_path
    assert_selector "h1", text: "Already Read"
  end

  test "should show read articles in already read section" do
    visit_read_articles_index

    assert_selector "article.article-card[data-source='#{@read_article.source_type}']"
    within("article.article-card[data-source='#{@read_article.source_type}']") do
      assert_text @read_article.title
    end
  end

  test "should be able to unmark article as read from already read section" do
    visit_read_articles_index

    within("article.article-card[data-source='#{@read_article.source_type}']") do
      find("button[title='Mark as unread']").click
    end
    find("[data-testid='confirm-dialog-confirm']").click

    sleep 0.5
    assert_not @read_article.reload.read?
  end

  test "should work with both bookmark and read functionality together" do
    # Start with clean article
    @article.unbookmark! if @article.bookmarked?
    @article.unmark_as_read! if @article.read?

    # Visit article detail and bookmark it
    visit_article_show(@article)
    click_button "Add to Reading List"
    sleep 0.5
    assert @article.reload.bookmarked?

    # Mark as read from same page
    click_button "Mark as Read"
    sleep 0.5
    assert @article.reload.read?

    # Refresh page to see updated status
    visit_article_show(@article)

    # Should show both statuses
    assert_selector "span", text: "Bookmarked"
    assert_selector "span", text: "Already Read"
  end

  test "should handle multiple articles workflow" do
    # Mark multiple articles as read
    visit_article_show(@article)
    click_button "Mark as Read"
    sleep 0.5

    visit_article_show(@bookmarked_article)
    click_button "Mark as Read"
    sleep 0.5

    # Visit already read section
    visit_read_articles_index
    assert_selector "article.article-card", minimum: 2
  end

  test "should show empty state when no read articles exist" do
    # Unmark all articles as read
    Article.read.each(&:unmark_as_read!)

    visit_read_articles_index

    assert_selector "h2", text: "No read articles yet"
    assert_link "Browse Articles", href: articles_path
  end
end
