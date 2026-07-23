require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "should send Content-Security-Policy header on HTML responses" do
    get root_url
    assert_response :success

    policy = response.headers["Content-Security-Policy"]
    assert_not_nil policy
    assert_includes policy, "default-src 'self'"
    assert_includes policy, "script-src 'self'"
    assert_includes policy, "style-src 'self' 'unsafe-inline'"
    assert_includes policy, "connect-src 'self'"
    assert_includes policy, "frame-ancestors 'none'"
  end

  test "should keep Vite module scripts allowed under CSP" do
    get articles_url
    assert_response :success

    assert_select "script[type='module'][src*='application']"
    assert_includes response.headers["Content-Security-Policy"], "script-src 'self'"
  end
end
