import type { ReadArticle } from '../types/readArticle'
import ArticleCard from './ArticleCard'

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
    <div className="grid gap-5 md:gap-6 motion-safe:animate-scale-in motion-sensitive">
      {filtered.map((article, index) => (
        <ArticleCard
          key={article.id}
          variant="read"
          article={article}
          index={index}
          onUnmarkRead={onUnmarkRead}
        />
      ))}
    </div>
  )
}
