module ArticlesHelper
  def group_sources_by_category(articles_by_source)
    categories = {
      "Programming Languages" => %w[reddit_ruby reddit_rust reddit_javascript],
      "Web Development" => %w[reddit_webdev reddit_programming],
      "Security" => %w[reddit_netsec reddit_cybersecurity],
      "AI & Machine Learning" => %w[reddit_MachineLearning reddit_artificial reddit_LocalLLaMA],
      "General Tech" => %w[hacker_news dev_to reddit_technology]
    }

    grouped = {}

    categories.each do |category_name, source_types|
      category_articles = []
      source_types.each do |source_type|
        category_articles.concat(articles_by_source[source_type] || [])
      end
      grouped[category_name] = category_articles if category_articles.any?
    end

    # Add any sources not in predefined categories
    other_sources = articles_by_source.keys - categories.values.flatten
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
end
