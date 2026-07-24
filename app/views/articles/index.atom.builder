atom_feed(language: "en-US", root_url: articles_url, url: articles_url(format: :atom)) do |feed|
  feed.title("Dev News Aggregator")
  feed.updated(@articles.first&.published_at || @last_updated || Time.current)

  @articles.each do |article|
    feed.entry(
      article,
      url: article.url,
      id: article_url(article),
      published: article.published_at,
      updated: article.updated_at
    ) do |entry|
      entry.title(article.title)
      entry.content(article.description.to_s, type: "text")
      entry.author { |author| author.name(article.source_type.to_s.tr("_", " ")) }
      entry.category(term: article.source_type)
    end
  end
end
