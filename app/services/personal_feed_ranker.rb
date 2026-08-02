# Ranks the article feed from single-user preference signals.
#
# v1: source_type affinity - boost sources that appear in bookmarks,
# demote sources that appear in permanent dismissals. Cold start
# (no signals) falls back to newest-first.
class PersonalFeedRanker
  def self.apply(scope)
    new.apply(scope)
  end

  def apply(scope)
    weights = source_type_weights
    return scope.order(published_at: :desc) if weights.empty?

    preference = preference_order_node(weights)
    score = Arel.sql("score DESC NULLS LAST")

    scope.order(preference, score, published_at: :desc)
  end

  def source_type_weights
    bookmark_counts = Bookmark.joins(:article).group("articles.source_type").count
    dismissal_counts = DismissedArticle.where(permanent: true)
                                       .joins(:article)
                                       .group("articles.source_type")
                                       .count

    source_types = (bookmark_counts.keys + dismissal_counts.keys).uniq
    return {} if source_types.empty?

    source_types.index_with do |source_type|
      bookmark_counts.fetch(source_type, 0) - dismissal_counts.fetch(source_type, 0)
    end
  end

  private

  def preference_order_node(weights)
    casing = Arel::Nodes::Case.new(Article.arel_table[:source_type])
    weights.each do |source_type, weight|
      casing.when(Arel::Nodes.build_quoted(source_type), weight.to_i)
    end
    casing.else(0)
    Arel::Nodes::Descending.new(casing)
  end
end
