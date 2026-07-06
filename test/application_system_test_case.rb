require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  class << self
    def ensure_vite_test_build!
      return if @vite_test_build_ready

      manifest = Rails.root.join("public/vite-test/.vite/manifest.json")
      unless manifest.exist?
        success = system({ "RAILS_ENV" => "test" }, "npm run build:test", chdir: Rails.root)
        raise "Vite test build failed. Run: npm run build:test" unless success
      end

      @vite_test_build_ready = true
    end
  end

  ensure_vite_test_build!

  def visit_articles_index
    visit articles_path
    unless page.has_selector?("[data-testid='articles-page']", wait: 12)
      visit articles_path
    end
    assert_selector "[data-testid='articles-page']", wait: 12
    assert_selector "main#main-content", wait: 12
    assert_no_text "Loading articles...", wait: 12
  end

  def visit_bookmarks_index
    visit bookmarks_path
    unless page.has_selector?("[data-testid='bookmarks-page']", wait: 12)
      visit bookmarks_path
    end
    assert_selector "[data-testid='bookmarks-page']", wait: 12
    assert_no_text "Loading reading list...", wait: 12
  end

  def visit_read_articles_index
    visit read_articles_path
    unless page.has_selector?("[data-testid='read-articles-page']", wait: 12)
      visit read_articles_path
    end
    assert_selector "[data-testid='read-articles-page']", wait: 12
    assert_no_text "Loading read articles...", wait: 12
  end

  def visit_dismissed_articles_index
    visit dismissed_articles_path
    unless page.has_selector?("[data-testid='dismissed-articles-page']", wait: 12)
      visit dismissed_articles_path
    end
    assert_selector "[data-testid='dismissed-articles-page']", wait: 12
    assert_no_text "Loading dismissed articles...", wait: 12
  end

  def visit_recently_dismissed
    visit recently_dismissed_path
    unless page.has_selector?("[data-testid='recently-dismissed-page']", wait: 12)
      visit recently_dismissed_path
    end
    assert_selector "[data-testid='recently-dismissed-page']", wait: 12
    assert_no_text "Loading recently dismissed articles...", wait: 12
  end

  def visit_article_show(article)
    visit article_path(article)
    unless page.has_selector?("[data-testid='article-show-page']", wait: 12)
      visit article_path(article)
    end
    assert_selector "[data-testid='article-show-page']", wait: 12
    assert_no_text "Loading article...", wait: 12
  end
end
