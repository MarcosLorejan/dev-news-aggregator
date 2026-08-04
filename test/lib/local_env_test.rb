# frozen_string_literal: true

require "test_helper"

class LocalEnvTest < ActiveSupport::TestCase
  def setup
    @path = Rails.root.join("tmp/local_env_test.env")
    @previous = LocalEnv::ALLOWLIST.index_with { |key| ENV[key] }
  end

  def teardown
    FileUtils.rm_f(@path)
    LocalEnv::ALLOWLIST.each do |key|
      previous = @previous[key]
      if previous.nil?
        ENV.delete(key)
      else
        ENV[key] = previous
      end
    end
  end

  test "load! sets allowlisted keys from dotenv file when unset" do
    ENV.delete("REDDIT_CLIENT_ID")
    ENV.delete("REDDIT_CLIENT_SECRET")
    ENV.delete("YOUTUBE_API_KEY")

    File.write(@path, <<~ENV)
      # comment
      REDDIT_CLIENT_ID=abc123
      REDDIT_CLIENT_SECRET="sec ret"
      YOUTUBE_API_KEY='yt-key'
      UNKNOWN_SHOULD_IGNORE=nope
    ENV

    loaded = LocalEnv.load!(path: @path.to_s)
    assert_operator loaded, :>=, 3
    assert_equal "abc123", ENV["REDDIT_CLIENT_ID"]
    assert_equal "sec ret", ENV["REDDIT_CLIENT_SECRET"]
    assert_equal "yt-key", ENV["YOUTUBE_API_KEY"]
    assert_nil ENV["UNKNOWN_SHOULD_IGNORE"]
  end

  test "load! does not overwrite existing ENV by default" do
    ENV["REDDIT_CLIENT_ID"] = "already-set"
    File.write(@path, "REDDIT_CLIENT_ID=from-file\n")

    LocalEnv.load!(path: @path.to_s)
    assert_equal "already-set", ENV["REDDIT_CLIENT_ID"]
  end

  test "present_masked never returns the secret value" do
    ENV["REDDIT_CLIENT_SECRET"] = "super-secret-value"
    masked = LocalEnv.present_masked("REDDIT_CLIENT_SECRET")

    assert_equal true, masked[:present]
    assert_equal "super-secret-value".length, masked[:length]
    assert_equal "REDDIT_CLIENT_SECRET", masked[:key]
    assert_nil masked[:value]
    refute_includes masked.inspect, "super-secret-value"
  end
end
