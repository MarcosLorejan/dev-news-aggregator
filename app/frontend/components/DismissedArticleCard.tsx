import type { DismissedArticle } from '../types/dismissedArticle'
import { formatBookmarkedDate, formatTimeAgo } from '../utils/format'
import ArticleCardBase from './ArticleCardBase'

interface DismissedArticleCardProps {
  article: DismissedArticle
  index: number
  variant: 'dismissed' | 'recent'
  onRestore: (article: DismissedArticle) => void
}

export default function DismissedArticleCard({
  article,
  index,
  variant,
  onRestore,
}: DismissedArticleCardProps) {
  const isRecent = variant === 'recent'
  const theme = isRecent ? 'orange' : 'red'
  const borderClass = isRecent ? 'border-orange-500/20' : 'border-red-500/20'
  const restoreLabel = isRecent ? 'Quick Restore' : 'Restore'

  const handleRestore = () => {
    if (!isRecent && !window.confirm('Restore this article to your main feed?')) {
      return
    }
    onRestore(article)
  }

  const badgeText = isRecent
    ? article.dismissed_at
      ? formatTimeAgo(article.dismissed_at)
      : 'Recently'
    : article.dismissed_at
      ? `Dismissed ${formatBookmarkedDate(article.dismissed_at)}`
      : 'Dismissed'

  const styles = isRecent
    ? 'bg-gradient-to-r from-orange-600/20 to-orange-700/20 text-orange-300 border border-orange-500/30'
    : 'bg-gradient-to-r from-red-600/20 to-red-700/20 text-red-300 border border-red-500/30'

  return (
    <ArticleCardBase
      article={article}
      index={index}
      theme={theme}
      borderClass={borderClass}
      showSourceBadge={false}
      badge={
        <span className={`inline-block px-3 py-1.5 text-xs font-semibold rounded-full ${styles}`}>
          {badgeText}
        </span>
      }
      actions={
        <button
          type="button"
          className="group/restore px-4 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg font-medium transition-all duration-200 hover:from-green-700 hover:to-green-800 hover:scale-105 hover:shadow-lg hover:shadow-green-500/25"
          title="Restore article"
          onClick={handleRestore}
        >
          <span className="flex items-center">
            <svg
              className="w-4 h-4 mr-2 transition-transform group-hover/restore:scale-110"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            {restoreLabel}
          </span>
        </button>
      }
    />
  )
}
