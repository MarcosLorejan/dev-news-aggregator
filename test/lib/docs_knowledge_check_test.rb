# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require_relative "../../lib/docs_knowledge_check"

class DocsKnowledgeCheckTest < ActiveSupport::TestCase
  def with_fixture_repo
    Dir.mktmpdir("docs-knowledge-check-") do |dir|
      root = Pathname(dir)
      FileUtils.mkdir_p(root.join("docs/decisions"))
      yield root
    end
  end

  def write(root, relative, contents)
    path = root.join(relative)
    FileUtils.mkdir_p(path.dirname)
    path.write(contents)
  end

  test "passes when links resolve and index lists every doc" do
    with_fixture_repo do |root|
      write(root, "docs/index.md", <<~MD)
        # Map
        - [Guide](guide.md)
        - [Decision](decisions/why.md)
      MD
      write(root, "docs/guide.md", "[decision](decisions/why.md)\n")
      write(root, "docs/decisions/why.md", "ok\n")
      write(root, "AGENTS.md", "See [guide](docs/guide.md)\n")

      result = DocsKnowledgeCheck.run(root: root)

      assert_predicate result, :ok?, result.errors.inspect
    end
  end

  test "fails on broken relative markdown links" do
    with_fixture_repo do |root|
      write(root, "docs/index.md", "- [Guide](guide.md)\n")
      write(root, "docs/guide.md", "[missing](nope.md)\n")

      result = DocsKnowledgeCheck.run(root: root)

      assert_not result.ok?
      assert result.errors.any? { |e| e.include?("broken link") && e.include?("nope.md") },
             result.errors.inspect
    end
  end

  test "fails when a docs file is missing from the knowledge map" do
    with_fixture_repo do |root|
      write(root, "docs/index.md", "- [Guide](guide.md)\n")
      write(root, "docs/guide.md", "ok\n")
      write(root, "docs/orphan.md", "forgotten\n")

      result = DocsKnowledgeCheck.run(root: root)

      assert_not result.ok?
      assert result.errors.any? { |e| e.include?("docs/orphan.md") && e.include?("not listed") },
             result.errors.inspect
    end
  end

  test "ignores external and anchor-only links" do
    with_fixture_repo do |root|
      write(root, "docs/index.md", <<~MD)
        - [Guide](guide.md)
        - [Site](https://example.com/x)
        - [Jump](#section)
      MD
      write(root, "docs/guide.md", "[mail](mailto:a@b.c)\n")

      result = DocsKnowledgeCheck.run(root: root)

      assert_predicate result, :ok?, result.errors.inspect
    end
  end
end
