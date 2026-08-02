module ArticlesHelper
  CATEGORIES = {
    "Programming Languages" => %w[reddit_ruby reddit_rust reddit_javascript],
    "Web Development" => %w[reddit_webdev reddit_programming],
    "Security" => %w[reddit_netsec reddit_cybersecurity],
    "AI & Machine Learning" => %w[reddit_MachineLearning reddit_artificial reddit_LocalLLaMA],
    "General Tech" => %w[hacker_news dev_to reddit_technology]
  }.freeze

  KNOWN_SOURCE_TYPES = CATEGORIES.values.flatten.freeze
  YOUTUBE_SOURCE_PREFIX = "youtube_".freeze

  def group_sources_by_category(articles_by_source)
    grouped = {}

    CATEGORIES.each do |category_name, source_types|
      category_articles = []
      source_types.each do |source_type|
        category_articles.concat(articles_by_source[source_type] || [])
      end
      grouped[category_name] = category_articles if category_articles.any?
    end

    video_keys = youtube_source_types(articles_by_source.keys)
    if video_keys.any?
      grouped["Videos"] = video_keys.flat_map { |source_type| articles_by_source[source_type] || [] }
    end

    # Add any sources not in predefined categories (and not YouTube).
    other_sources = articles_by_source.keys - KNOWN_SOURCE_TYPES - video_keys
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
      "Videos" => "▶️",
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

    return :videos if category_slug("Videos") == slug
    return :other if category_slug("Other") == slug

    nil
  end

  def apply_category_filter(scope, slug)
    source_types = source_types_for_category_slug(slug)
    return scope if source_types.nil? && (slug.blank? || slug == "all")
    return scope.none if source_types.nil?

    case source_types
    when :videos
      scope.where("source_type LIKE ?", "#{YOUTUBE_SOURCE_PREFIX}%")
    when :other
      scope.where.not(source_type: KNOWN_SOURCE_TYPES)
           .where.not("source_type LIKE ?", "#{YOUTUBE_SOURCE_PREFIX}%")
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

    video_keys = youtube_source_types(counts_by_source.keys)
    video_count = video_keys.sum { |key| counts_by_source[key] || 0 }
    grouped["Videos"] = video_count if video_count.positive?

    other_count = counts_by_source.except(*KNOWN_SOURCE_TYPES, *video_keys).values.sum
    grouped["Other"] = other_count if other_count.positive?

    grouped
  end

  def youtube_source_types(source_types)
    Array(source_types).select { |source_type| source_type.to_s.start_with?(YOUTUBE_SOURCE_PREFIX) }
  end
end
