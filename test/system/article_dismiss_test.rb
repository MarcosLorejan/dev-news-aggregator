require "application_system_test_case"

class ArticleDismissTest < ApplicationSystemTestCase
  def setup
    @article = articles(:hacker_news_article)
    @dismissed_article = articles(:reddit_rust_article)
    @dismissed_article.dismiss!
    @dismissed_article.dismissed_article.update!(permanent: true)
  end

  test "should show dismiss button on each article" do
    visit articles_path

    within first("article.article-card") do
      assert_selector "button[title='Dismiss article']"
      assert_selector "svg", count: 4
    end
  end

  test "should dismiss article and show undo toast" do
    visit articles_path

    within first("article.article-card") do
      find("button[title='Dismiss article']").click
    end

    assert_selector ".dismiss-toast", visible: true
    assert_text "Article dismissed"
    assert_selector "button", text: "UNDO"
    assert_text "Ctrl+Z to undo"
    assert_text "15s remaining"
  end

  test "should make article semi-transparent when dismissed" do
    visit articles_path

    article_card = first("article.article-card")
    dismiss_button = article_card.find("button[title='Dismiss article']")
    dismiss_button.click

    sleep 0.5
    assert_equal "0.5", article_card.style("opacity")
  end

  test "should undo dismiss via toast UNDO button" do
    visit articles_path

    article_card = first("article.article-card")
    dismiss_button = article_card.find("button[title='Dismiss article']")
    dismiss_button.click

    within ".dismiss-toast" do
      click_button "UNDO"
    end

    sleep 0.5
    assert_equal "1", article_card.style("opacity")
    assert_no_selector ".dismiss-toast"
  end

  test "should undo dismiss by clicking faded article" do
    visit articles_path

    article_card = first("article.article-card")
    dismiss_button = article_card.find("button[title='Dismiss article']")
    dismiss_button.click

    sleep 0.5
    article_card.click

    sleep 0.5
    assert_equal "1", article_card.style("opacity")
    assert_no_selector ".dismiss-toast"
  end

  test "should show countdown timer in toast" do
    visit articles_path

    within first("article.article-card") do
      find("button[title='Dismiss article']").click
    end

    within ".dismiss-toast" do
      assert_text "15s remaining"
      assert_selector ".countdown-bar"
    end

    sleep 2

    within ".dismiss-toast" do
      assert_text "13s remaining"
    end
  end

  test "should navigate to recently dismissed page" do
    visit articles_path

    click_link "Recently Dismissed"

    assert_current_path recently_dismissed_path
    assert_selector "h1", text: "Recently Dismissed"
  end

  test "should show recently dismissed articles" do
    recent_dismissed = articles(:dev_to_article)
    recent_dismissed.dismiss!

    visit recently_dismissed_path

    assert_selector "article.article-card", minimum: 1
    assert_text "ago"
  end

  test "should navigate to all dismissed articles page" do
    visit articles_path

    click_link "Recently Dismissed"
    click_link "All Dismissed"

    assert_current_path dismissed_articles_path
    assert_selector "h1", text: "Dismissed Articles"
  end

  test "should show dismissed articles in dismissed index" do
    visit dismissed_articles_path

    assert_selector "article.article-card", minimum: 1
    within first("article.article-card") do
      assert_text "Dismissed"
      assert_selector "button", text: "Restore"
    end
  end

  test "should restore article from dismissed page" do
    visit dismissed_articles_path

    within first("article.article-card") do
      accept_confirm do
        click_button "Restore"
      end
    end

    assert_current_path dismissed_articles_path
    visit articles_path

    assert_selector "article.article-card", minimum: 1
  end

  test "should restore article from recently dismissed page" do
    recent_dismissed = articles(:dev_to_article)
    recent_dismissed.dismiss!

    visit recently_dismissed_path

    within first("article.article-card") do
      click_button "Quick Restore"
    end

    assert_current_path recently_dismissed_path
    visit articles_path

    assert_selector "article.article-card", minimum: 1
  end

  test "should exclude permanently dismissed articles from main feed" do
    @dismissed_article.dismissed_article.update!(permanent: true)

    visit articles_path

    within "body" do
      assert_no_text @dismissed_article.title
    end
  end

  test "should show empty state when no dismissed articles" do
    DismissedArticle.destroy_all

    visit dismissed_articles_path

    assert_selector "h2", text: "No dismissed articles"
    assert_text "You haven't dismissed any articles yet"
    assert_link "Browse Articles"
  end

  test "should show empty state when no recently dismissed articles" do
    DismissedArticle.where("dismissed_at > ?", 24.hours.ago).destroy_all

    visit recently_dismissed_path

    assert_selector "h2", text: "No recently dismissed articles"
    assert_text "You haven't dismissed any articles in the last 24 hours"
  end

  test "should handle dismiss API error gracefully" do
    page.execute_script("
      window.fetch = function() {
        return Promise.reject(new Error('Network error'))
      }
    ")

    visit articles_path

    article_card = first("article.article-card")
    dismiss_button = article_card.find("button[title='Dismiss article']")
    dismiss_button.click

    sleep 0.5
    assert_equal "1", article_card.style("opacity")
  end

  test "should handle multiple rapid dismissals" do
    visit articles_path

    articles = all("article.article-card").first(3)

    articles.each do |article|
      within article do
        find("button[title='Dismiss article']").click
      end
      sleep 0.2
    end

    assert_selector ".dismiss-toast", count: 1
  end

  test "should maintain filter functionality after dismissal" do
    visit articles_path

    if has_selector?("button.filter-btn[data-filter-type='category']")
      first("button.filter-btn[data-filter-type='category']").click

      within first("article.article-card") do
        find("button[title='Dismiss article']").click
      end

      within ".dismiss-toast" do
        click_button "UNDO"
      end

      assert_selector "article.article-card", visible: true
    else
      skip "No category filters available"
    end
  end
end
