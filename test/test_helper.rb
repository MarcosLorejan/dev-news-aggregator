ENV["RAILS_ENV"] ||= "test"
ENV["DISABLE_SPRING"] = "1"

# Configure SimpleCov for coverage reporting
if ENV["COVERAGE"] && ENV["COVERAGE"] != ""
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end

  # SimpleCov 1.0: formatters= expects an Array (it wraps MultiFormatter itself).
  # Passing MultiFormatter.new([...]) fails because that returns a Class, not an Array.
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ]

  SimpleCov.start "rails" do
    skip "/vendor/"
    skip "/test/"
    skip "/config/"
    skip "/db/"
    skip "/bin/"
    skip "/lib/tasks/"

    minimum_coverage 55

    cover "{app,lib}/**/*.rb"
  end
end

require_relative "../config/environment"
require "rails/test_help"
require "timecop"
require "ostruct"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers (disable when running coverage)
    parallelize(workers: :number_of_processors) unless ENV["COVERAGE"]

    parallelize_setup do |worker|
      next unless worker == 0

      manifest = Rails.root.join("public/vite-test/.vite/manifest.json")
      next if manifest.exist?

      success = system({ "RAILS_ENV" => "test" }, "npm run build:test", chdir: Rails.root)
      raise "Vite test build failed. Run: npm run build:test" unless success
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
