require "test_helper"

class ReactShellTest < ActionDispatch::IntegrationTest
  test "articles index renders react mount point and vite bundle" do
    get articles_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
    assert_select "link[rel='stylesheet'][href*='application']"
    assert_no_match(/entrypoints\/application\.ts["']/, response.body)
    assert_no_match(/cdn\.tailwindcss\.com/, response.body)
  end

  test "vite test manifest includes application.tsx entrypoint" do
    manifest_path = Rails.root.join("public/vite-test/.vite/manifest.json")
    skip "Run npm run build:test before this test" unless manifest_path.exist?

    manifest = JSON.parse(manifest_path.read)
    assert manifest.key?("entrypoints/application.tsx")
  end

  test "vite test manifest includes compiled tailwind css entrypoint" do
    manifest_path = Rails.root.join("public/vite-test/.vite/manifest.json")
    skip "Run npm run build:test before this test" unless manifest_path.exist?

    entry = JSON.parse(manifest_path.read).fetch("entrypoints/application.css")
    assert entry.fetch("file").end_with?(".css")
    assert_includes entry.fetch("file"), "application"
  end

  test "vite test manifest lazy-loads route page chunks" do
    manifest_path = Rails.root.join("public/vite-test/.vite/manifest.json")
    skip "Run npm run build:test before this test" unless manifest_path.exist?

    entry = JSON.parse(manifest_path.read).fetch("entrypoints/application.tsx")
    dynamic_imports = entry.fetch("dynamicImports")

    assert_includes dynamic_imports, "pages/ArticlesIndexPage.tsx"
    assert_includes dynamic_imports, "pages/ArticleShowPage.tsx"
    assert_includes dynamic_imports, "pages/BookmarksIndexPage.tsx"
    assert_equal 7, dynamic_imports.size
  end

  test "bookmarks index renders react mount point" do
    get bookmarks_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "read articles index renders react mount point" do
    get read_articles_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "dismissed articles index renders react mount point" do
    get dismissed_articles_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "recently dismissed renders react mount point" do
    get recently_dismissed_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "article show renders react mount point" do
    get article_path(articles(:hacker_news_article))

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end

  test "sources index renders react mount point" do
    get sources_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
  end
end
