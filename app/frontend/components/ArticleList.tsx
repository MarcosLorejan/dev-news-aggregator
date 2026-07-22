import type { Article } from '../types/article'
import ArticleCard from './ArticleCard'

interface ArticleListProps {
  articles: Article[]
  articleCategories: Record<number, string>
  dismissingIds: Set<number>
  onDismiss: (article: Article) => void
  onUndoDismiss: (article: Article) => void
  onBookmarkToggle: (article: Article) => void
  onReadToggle: (article: Article) => void
}

export default function ArticleList({
  articles,
  articleCategories,
  dismissingIds,
  onDismiss,
  onUndoDismiss,
  onBookmarkToggle,
  onReadToggle,
}: ArticleListProps) {
  return (
    <div className="grid gap-5 md:gap-6 motion-safe:animate-scale-in motion-sensitive">
      {articles.map((article, index) => (
        <ArticleCard
          key={article.id}
          variant="feed"
          article={article}
          categorySlug={articleCategories[article.id] ?? 'other'}
          index={index}
          isDismissing={dismissingIds.has(article.id)}
          onDismiss={onDismiss}
          onUndoDismiss={onUndoDismiss}
          onBookmarkToggle={onBookmarkToggle}
          onReadToggle={onReadToggle}
        />
      ))}
    </div>
  )
}
