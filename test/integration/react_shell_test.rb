require "test_helper"

class ReactShellTest < ActionDispatch::IntegrationTest
  test "articles index renders react mount point and vite bundle" do
    get articles_path

    assert_response :success
    assert_select "#root"
    assert_select "script[type='module'][src*='application']"
    assert_no_match(/entrypoints\/application\.ts["']/, response.body)
  end

  test "vite test manifest includes application.tsx entrypoint" do
    manifest_path = Rails.root.join("public/vite-test/.vite/manifest.json")
    skip "Run npm run build:test before this test" unless manifest_path.exist?

    manifest = JSON.parse(manifest_path.read)
    assert manifest.key?("entrypoints/application.tsx")
  end
end
