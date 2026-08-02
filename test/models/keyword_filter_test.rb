require "test_helper"

class KeywordFilterTest < ActiveSupport::TestCase
  test "requires a name" do
    filter = KeywordFilter.new(terms: [ "ruby" ])

    assert_not filter.valid?
    assert_includes filter.errors[:name], "can't be blank"
  end

  test "requires a unique name regardless of case" do
    filter = KeywordFilter.new(name: "ruby", terms: [ "ruby" ])

    assert_not filter.valid?
    assert_includes filter.errors[:name], "has already been taken"
  end

  test "derives a slug from the name" do
    filter = KeywordFilter.create!(name: "Software Architecture & Design", terms: [ "system design" ])

    assert_equal "software-architecture-design", filter.slug
  end

  test "keeps slugs unique" do
    KeywordFilter.create!(name: "AI performance", terms: [ "inference" ])
    duplicate = KeywordFilter.new(name: "ai  performance", terms: [ "latency" ])

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "normalizes terms on save" do
    filter = KeywordFilter.create!(
      name: "Mixed input",
      terms: [ "  Rust ", "rust", "RUST", "", "  ", "Software Architecture" ]
    )

    assert_equal [ "rust", "software architecture" ], filter.terms
  end

  test "rejects filters without any usable term" do
    filter = KeywordFilter.new(name: "Empty", terms: [ " ", "" ])

    assert_not filter.valid?
    assert_includes filter.errors[:terms], "must include at least one keyword"
  end

  test "caps the number of stored terms" do
    filter = KeywordFilter.create!(
      name: "Long list",
      terms: (1..Article::MAX_KEYWORDS + 5).map { |index| "term-#{index}" }
    )

    assert_equal Article::MAX_KEYWORDS, filter.terms.size
  end

  test "rejects overly long terms" do
    filter = KeywordFilter.new(name: "Too long", terms: [ "a" * (KeywordFilter::MAX_TERM_LENGTH + 1) ])

    assert_not filter.valid?
    assert_includes filter.errors[:terms], "must be #{KeywordFilter::MAX_TERM_LENGTH} characters or fewer each"
  end

  test "enabled scope skips inactive filters" do
    enabled = KeywordFilter.enabled

    assert_includes enabled, keyword_filters(:ruby_interest)
    assert_not_includes enabled, keyword_filters(:archived_interest)
  end

  test "ordered scope sorts by position then name" do
    KeywordFilter.update_all(position: 0)

    assert_equal KeywordFilter.pluck(:name).sort, KeywordFilter.ordered.pluck(:name)
  end

  test "bootstrap_defaults! seeds configured interests and is idempotent" do
    KeywordFilter.delete_all

    KeywordFilter.bootstrap_defaults!
    seeded = KeywordFilter.ordered.pluck(:name)

    assert_equal NewsAggregatorConfig.interests.map { |interest| interest[:name] }, seeded
    assert KeywordFilter.find_by(slug: "software-architecture").terms.include?("system design")

    assert_no_difference -> { KeywordFilter.count } do
      KeywordFilter.bootstrap_defaults!
    end
  end

  test "bootstrap_defaults! leaves existing interests untouched" do
    KeywordFilter.delete_all
    custom = KeywordFilter.create!(name: "Ruby", terms: [ "my own term" ])

    KeywordFilter.bootstrap_defaults!

    assert_equal [ "my own term" ], custom.reload.terms
  end
end
