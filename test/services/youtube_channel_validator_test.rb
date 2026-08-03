require "test_helper"

class YoutubeChannelValidatorTest < ActiveSupport::TestCase
  CHANNEL_ID = "UCWnPjmqvljcafA0QXblOU1A"

  setup do
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
    ENV.delete("YOUTUBE_API_KEY") if ENV["YOUTUBE_API_KEY"] == "test-key"
  end

  test "resolves a bare channel ID when Atom feed is valid" do
    stub_atom_feed(CHANNEL_ID, title: "Confreaks")

    result = YoutubeChannelValidator.resolve(CHANNEL_ID)

    assert result.valid?
    assert_equal CHANNEL_ID, result.channel_id
    assert_equal "Confreaks", result.channel_name
  end

  test "resolves a channel URL" do
    stub_atom_feed(CHANNEL_ID, title: "Confreaks")

    result = YoutubeChannelValidator.resolve("https://www.youtube.com/channel/#{CHANNEL_ID}")

    assert result.valid?
    assert_equal CHANNEL_ID, result.channel_id
  end

  test "resolves an @handle via page scrape when no API key" do
    stub_request(:get, "https://www.youtube.com/@fireship")
      .to_return(
        status: 200,
        body: %(<html>"channelId":"#{CHANNEL_ID}"</html>),
        headers: { "Content-Type" => "text/html" }
      )
    stub_atom_feed(CHANNEL_ID, title: "Fireship")

    result = YoutubeChannelValidator.resolve("@fireship")

    assert result.valid?
    assert_equal CHANNEL_ID, result.channel_id
    assert_equal "Fireship", result.channel_name
  end

  test "resolves a handle via channels.list when API key is set" do
    ENV["YOUTUBE_API_KEY"] = "test-key"
    stub_request(:get, %r{https://www\.googleapis\.com/youtube/v3/channels})
      .with(query: hash_including("forHandle" => "fireship", "key" => "test-key"))
      .to_return(
        status: 200,
        body: { items: [ { "id" => CHANNEL_ID } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    stub_atom_feed(CHANNEL_ID, title: "Fireship")

    result = YoutubeChannelValidator.resolve("https://www.youtube.com/@fireship")

    assert result.valid?
    assert_equal CHANNEL_ID, result.channel_id
  end

  test "rejects blank input" do
    result = YoutubeChannelValidator.resolve("  ")

    refute result.valid?
    assert_match(/required/i, result.error)
  end

  test "rejects when Atom feed is missing" do
    stub_request(:get, %r{youtube\.com/feeds/videos\.xml})
      .with(query: hash_including("channel_id" => CHANNEL_ID))
      .to_return(status: 404, body: "not found")

    result = YoutubeChannelValidator.resolve(CHANNEL_ID)

    refute result.valid?
    assert_match(/not found|unavailable/i, result.error)
  end

  private

  def stub_atom_feed(channel_id, title:)
    body = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>#{title}</title>
        <author><name>#{title}</name></author>
        <entry><title>Sample</title></entry>
      </feed>
    XML

    stub_request(:get, %r{youtube\.com/feeds/videos\.xml})
      .with(query: hash_including("channel_id" => channel_id))
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/atom+xml" })
  end
end
