atom_feed(language: "en-US", root_url: bookmarks_url, url: bookmarks_url(format: :atom)) do |feed|
  feed.title("Dev News Aggregator — Reading List")
  feed.updated(@bookmarked_articles.first&.bookmark&.bookmarked_at || Time.current)

  @bookmarked_articles.each do |article|
    feed.entry(
      article,
      url: article.url,
      id: article_url(article),
      published: article.bookmark&.bookmarked_at || article.published_at,
      updated: article.updated_at
    ) do |entry|
      entry.title(article.title)
      entry.content(article.description.to_s, type: "text")
      entry.author { |author| author.name(article.source_type.to_s.tr("_", " ")) }
      entry.category(term: article.source_type)
    end
  end
end
