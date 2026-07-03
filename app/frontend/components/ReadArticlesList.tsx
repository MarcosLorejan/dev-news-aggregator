import type { ReadArticle } from '../types/readArticle'
import ReadArticleCard from './ReadArticleCard'

interface ReadArticlesListProps {
  articles: ReadArticle[]
  activeSource: string
  onUnmarkRead: (article: ReadArticle) => void
}

export default function ReadArticlesList({
  articles,
  activeSource,
  onUnmarkRead,
}: ReadArticlesListProps) {
  const filtered =
    activeSource === 'all'
      ? articles
      : articles.filter((article) => article.source_type === activeSource)

  return (
    <div className="grid gap-6 animate-scale-in">
      {filtered.map((article, index) => (
        <ReadArticleCard
          key={article.id}
          article={article}
          index={index}
          onUnmarkRead={onUnmarkRead}
        />
      ))}
    </div>
  )
}
