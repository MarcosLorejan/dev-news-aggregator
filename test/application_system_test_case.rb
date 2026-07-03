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
    assert_selector "[data-testid='articles-page']", wait: 10
    assert_no_text "Loading articles...", wait: 10
  end
end
