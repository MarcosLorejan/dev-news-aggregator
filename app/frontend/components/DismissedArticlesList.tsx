import type { DismissedArticle } from '../types/dismissedArticle'
import DismissedArticleCard from './DismissedArticleCard'

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
  return (
    <div className="grid gap-6 animate-scale-in">
      {articles.map((article, index) => (
        <DismissedArticleCard
          key={article.id}
          article={article}
          index={index}
          variant={variant}
          onRestore={onRestore}
        />
      ))}
    </div>
  )
}
