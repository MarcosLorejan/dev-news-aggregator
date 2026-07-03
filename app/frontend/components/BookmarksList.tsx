import type { BookmarkArticle } from '../types/bookmark'
import BookmarkCard from './BookmarkCard'

interface BookmarksListProps {
  articles: BookmarkArticle[]
  activeSource: string
  onRemoveBookmark: (article: BookmarkArticle) => void
  onReadToggle: (article: BookmarkArticle) => void
}

export default function BookmarksList({
  articles,
  activeSource,
  onRemoveBookmark,
  onReadToggle,
}: BookmarksListProps) {
  const visibleArticles =
    activeSource === 'all'
      ? articles
      : articles.filter((article) => article.source_type === activeSource)

  return (
    <div className="grid gap-6 animate-scale-in">
      {visibleArticles.map((article, index) => (
        <BookmarkCard
          key={article.id}
          article={article}
          index={index}
          onRemoveBookmark={onRemoveBookmark}
          onReadToggle={onReadToggle}
        />
      ))}
    </div>
  )
}
