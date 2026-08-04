require "test_helper"

class YoutubeThumbnailTest < ActiveSupport::TestCase
  test "preferred_url upgrades Atom hqdefault stills to maxresdefault" do
    url = YoutubeThumbnail.preferred_url(
      "https://i.ytimg.com/vi/abc123XYZ/hqdefault.jpg",
      video_id: "abc123XYZ"
    )

    assert_equal "https://i.ytimg.com/vi/abc123XYZ/maxresdefault.jpg", url
  end

  test "preferred_url derives video id from thumbnail path" do
    url = YoutubeThumbnail.preferred_url("https://i.ytimg.com/vi/abc123XYZ/mqdefault.jpg")

    assert_equal "https://i.ytimg.com/vi/abc123XYZ/maxresdefault.jpg", url
  end

  test "preferred_url returns original when video id is missing" do
    assert_equal "https://example.com/thumb.jpg", YoutubeThumbnail.preferred_url("https://example.com/thumb.jpg")
    assert_nil YoutubeThumbnail.preferred_url(nil)
  end
end
