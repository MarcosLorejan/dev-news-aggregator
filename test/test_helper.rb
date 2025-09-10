ENV["RAILS_ENV"] ||= "test"
ENV["DISABLE_SPRING"] = "1"

# Configure SimpleCov for coverage reporting
if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])

  SimpleCov.start "rails" do
    add_filter "/vendor/"
    add_filter "/test/"
    add_filter "/config/"
    add_filter "/db/"
    add_filter "/bin/"
    add_filter "/lib/tasks/"

    minimum_coverage 55

    track_files "{app,lib}/**/*.rb"
  end
end

require_relative "../config/environment"
require "rails/test_help"
require "timecop"
require "ostruct"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers (disable when running coverage)
    parallelize(workers: :number_of_processors) unless ENV["COVERAGE"]

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
