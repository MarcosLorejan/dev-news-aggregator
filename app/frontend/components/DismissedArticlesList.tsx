import type { DismissedArticle } from '../types/dismissedArticle'
import ArticleCard from './ArticleCard'

interface DismissedArticlesListProps {
  articles: DismissedArticle[]
  variant: 'dismissed' | 'recent'
  onRestore: (article: DismissedArticle) => void
}

export default function DismissedArticlesList({
  articles,
  variant,
  onRestore,
}: DismissedArticlesListProps) {
  const cardVariant = variant === 'recent' ? 'recent-dismissed' : 'dismissed'

  return (
    <div className="grid gap-5 md:gap-6 motion-safe:animate-scale-in motion-sensitive">
      {articles.map((article, index) => (
        <ArticleCard
          key={article.id}
          variant={cardVariant}
          article={article}
          index={index}
          onRestore={onRestore}
        />
      ))}
    </div>
  )
}
