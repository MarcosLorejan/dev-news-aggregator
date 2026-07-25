require "test_helper"

class UrlCanonicalizerTest < ActiveSupport::TestCase
  test "strips www tracking params and trailing slash" do
    url = "https://WWW.Example.com/path/story/?utm_source=hn&utm_medium=social&fbclid=abc&id=42"
    assert_equal "https://example.com/path/story?id=42", UrlCanonicalizer.canonicalize(url)
  end

  test "returns nil for blank or invalid urls" do
    assert_nil UrlCanonicalizer.canonicalize("")
    assert_nil UrlCanonicalizer.canonicalize("not a url")
  end

  test "keeps non-tracking query params sorted" do
    url = "https://example.com/a?b=2&a=1"
    assert_equal "https://example.com/a?a=1&b=2", UrlCanonicalizer.canonicalize(url)
  end
end
