require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "layout links the web app manifest" do
    get articles_path

    assert_response :success
    assert_select "link[rel='manifest'][href='/manifest.json']"
  end

  test "manifest describes an installable app" do
    get pwa_manifest_path(format: :json)

    assert_response :success

    manifest = JSON.parse(response.body)
    assert_equal "Dev News Aggregator", manifest["name"]
    assert_equal "Dev News", manifest["short_name"]
    assert_equal "/", manifest["start_url"]
    assert_equal "standalone", manifest["display"]
    assert manifest["icons"].any? { |icon| icon["sizes"] == "512x512" }
    assert manifest["icons"].any? { |icon| icon["purpose"] == "maskable" }
  end

  test "service worker registers a fetch handler so browsers offer the install prompt" do
    get pwa_service_worker_path

    assert_response :success
    assert_match(/addEventListener\("fetch"/, response.body)
  end
end
