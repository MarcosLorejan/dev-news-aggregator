module ArticlesHelper
  CATEGORIES = {
    "Programming Languages" => %w[reddit_ruby reddit_rust reddit_javascript],
    "Web Development" => %w[reddit_webdev reddit_programming],
    "Security" => %w[reddit_netsec reddit_cybersecurity],
    "AI & Machine Learning" => %w[reddit_MachineLearning reddit_artificial reddit_LocalLLaMA],
    "General Tech" => %w[hacker_news dev_to reddit_technology]
  }.freeze

  KNOWN_SOURCE_TYPES = CATEGORIES.values.flatten.freeze

  def group_sources_by_category(articles_by_source)
    grouped = {}

    CATEGORIES.each do |category_name, source_types|
      category_articles = []
      source_types.each do |source_type|
        category_articles.concat(articles_by_source[source_type] || [])
      end
      grouped[category_name] = category_articles if category_articles.any?
    end

    # Add any sources not in predefined categories
    other_sources = articles_by_source.keys - KNOWN_SOURCE_TYPES
    if other_sources.any?
      other_articles = []
      other_sources.each do |source_type|
        other_articles.concat(articles_by_source[source_type])
      end
      grouped["Other"] = other_articles if other_articles.any?
    end

    grouped
  end

  def category_icon(category_name)
    icons = {
      "Programming Languages" => "🔨",
      "Web Development" => "🌐",
      "Security" => "🔒",
      "AI & Machine Learning" => "🤖",
      "General Tech" => "💻",
      "Other" => "📰"
    }
    icons[category_name] || "📄"
  end

  # Matches frontend parameterize(): lowercase + spaces to hyphens (keeps & etc.)
  def category_slug(name)
    name.to_s.downcase.gsub(/\s+/, "-")
  end

  def source_types_for_category_slug(slug)
    return nil if slug.blank? || slug == "all"

    CATEGORIES.each do |name, source_types|
      return source_types if category_slug(name) == slug
    end

    return :other if category_slug("Other") == slug

    nil
  end

  def apply_category_filter(scope, slug)
    source_types = source_types_for_category_slug(slug)
    return scope if source_types.nil? && (slug.blank? || slug == "all")
    return scope.none if source_types.nil?

    if source_types == :other
      scope.where.not(source_type: KNOWN_SOURCE_TYPES)
    else
      scope.where(source_type: source_types)
    end
  end

  def category_counts_for_scope(scope)
    counts_by_source = scope.unscope(:includes, :order, :select).group(:source_type).count
    group_counts_by_category(counts_by_source)
  end

  def group_counts_by_category(counts_by_source)
    grouped = {}

    CATEGORIES.each do |category_name, source_types|
      count = source_types.sum { |source_type| counts_by_source[source_type] || 0 }
      grouped[category_name] = count if count.positive?
    end

    other_count = counts_by_source.except(*KNOWN_SOURCE_TYPES).values.sum
    grouped["Other"] = other_count if other_count.positive?

    grouped
  end
end
