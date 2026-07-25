# Collapses duplicate stories that share a canonical URL into one primary
# article (highest score, then newest) and exposes sibling sources.
class ArticleClusterer
  def self.primaries(scope)
    new.primaries(scope)
  end

  def self.related_by_article_id(articles)
    new.related_by_article_id(articles)
  end

  def primaries(scope)
    filtered = scope.except(:select, :order, :includes, :preload, :eager_load, :limit, :offset)
    id_sql = filtered.reselect("articles.id").to_sql

    ranked_sql = <<~SQL.squish
      SELECT ranked.id
      FROM (
        SELECT articles.id AS id,
               ROW_NUMBER() OVER (
                 PARTITION BY COALESCE(
                   NULLIF(articles.canonical_url, ''),
                   CONCAT('article-', articles.id::text)
                 )
                 ORDER BY articles.score DESC NULLS LAST,
                          articles.published_at DESC,
                          articles.id DESC
               ) AS rn
        FROM articles
        WHERE articles.id IN (#{id_sql})
      ) ranked
      WHERE ranked.rn = 1
    SQL

    primary_ids = Article.connection.select_values(ranked_sql)
    Article.where(id: primary_ids)
  end

  def related_by_article_id(articles)
    list = Array(articles)
    urls = list.filter_map { |article| article.canonical_url.presence }.uniq
    return {} if urls.empty?

    siblings = Article.where(canonical_url: urls)
                      .where.not(id: list.map(&:id))
                      .order(Arel.sql("score DESC NULLS LAST"), published_at: :desc)

    by_url = siblings.group_by(&:canonical_url)
    list.each_with_object({}) do |article, hash|
      next if article.canonical_url.blank?

      related = by_url[article.canonical_url]
      hash[article.id] = related if related.present?
    end
  end
end
