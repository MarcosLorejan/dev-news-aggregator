import type { Article } from '../types/article'
import ArticleCard from './ArticleCard'

interface ArticleListProps {
  articles: Article[]
  articleCategories: Record<number, string>
  activeFilter: string
  dismissingIds: Set<number>
  onDismiss: (article: Article) => void
  onUndoDismiss: (article: Article) => void
  onBookmarkToggle: (article: Article) => void
  onReadToggle: (article: Article) => void
}

export default function ArticleList({
  articles,
  articleCategories,
  activeFilter,
  dismissingIds,
  onDismiss,
  onUndoDismiss,
  onBookmarkToggle,
  onReadToggle,
}: ArticleListProps) {
  const visibleArticles = articles.filter((article) => {
    if (activeFilter === 'all') return true
    const categorySlug = articleCategories[article.id] ?? 'other'
    return categorySlug === activeFilter
  })

  return (
    <div className="grid gap-6 animate-scale-in">
      {visibleArticles.map((article, index) => (
        <ArticleCard
          key={article.id}
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
