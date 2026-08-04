# frozen_string_literal: true

require "pathname"

# Dependency-free checks for docs knowledge hygiene (OKF-inspired).
# See docs/KNOWLEDGE.md and issue #411.
module DocsKnowledgeCheck
  ROOT_ENTRY_FILES = %w[AGENTS.md CONTRIBUTING.md].freeze
  INDEX_REL = "docs/index.md"
  DOCS_GLOB = "docs/**/*.md"
  LINK_RE = /\[(?:[^\]]*)\]\(([^)]+)\)/

  Result = Struct.new(:errors, keyword_init: true) do
    def ok?
      errors.empty?
    end
  end

  module_function

  def run(root:)
    root = Pathname(root).expand_path
    errors = []
    errors.concat(broken_links(root))
    errors.concat(orphans(root))
    Result.new(errors: errors)
  end

  def broken_links(root)
    errors = []
    markdown_files(root).each do |file|
      relative_file = file.relative_path_from(root).to_s
      each_relative_link(file) do |raw_target, line_no|
        target = resolve_link(file, raw_target)
        next if target.nil?

        unless target.exist?
          errors << "#{relative_file}:#{line_no}: broken link -> #{raw_target}"
        end
      end
    end
    errors
  end

  def orphans(root)
    index = root.join(INDEX_REL)
    return [ "#{INDEX_REL}: missing knowledge map" ] unless index.exist?

    listed = linked_doc_paths(root, index)
    errors = []

    root.glob(DOCS_GLOB).sort.each do |file|
      rel = file.relative_path_from(root).to_s
      next if rel == INDEX_REL
      next if listed.include?(rel)

      errors << "#{rel}: not listed in #{INDEX_REL}"
    end
    errors
  end

  def markdown_files(root)
    files = root.glob(DOCS_GLOB)
    ROOT_ENTRY_FILES.each do |name|
      path = root.join(name)
      files << path if path.exist?
    end
    files.sort
  end

  def each_relative_link(file)
    file.each_line.with_index(1) do |line, line_no|
      line.scan(LINK_RE) do |match|
        raw = match[0].strip
        next if skip_link?(raw)

        yield raw, line_no
      end
    end
  end

  def skip_link?(raw)
    return true if raw.empty?
    return true if raw.start_with?("#", "http://", "https://", "mailto:")

    false
  end

  def resolve_link(from_file, raw)
    path_part = raw.split("#", 2).first
    return nil if path_part.nil? || path_part.empty?

    (from_file.dirname + path_part).cleanpath
  end

  def linked_doc_paths(root, index_file)
    listed = {}
    each_relative_link(index_file) do |raw, _line|
      target = resolve_link(index_file, raw)
      next if target.nil?

      begin
        rel = target.relative_path_from(root).to_s.tr("\\", "/")
      rescue ArgumentError
        next
      end
      next unless rel.start_with?("docs/") && rel.end_with?(".md")

      listed[rel] = true
    end
    listed
  end
  private_class_method :markdown_files, :each_relative_link, :skip_link?,
                       :resolve_link, :linked_doc_paths
end
