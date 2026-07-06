import type { Article } from '../types/article'
import ArticleCardBase from './ArticleCardBase'

interface ArticleCardProps {
  article: Article
  categorySlug: string
  index: number
  isDismissing: boolean
  onDismiss: (article: Article) => void
  onUndoDismiss?: (article: Article) => void
  onBookmarkToggle: (article: Article) => void
  onReadToggle: (article: Article) => void
}

export default function ArticleCard({
  article,
  categorySlug,
  index,
  isDismissing,
  onDismiss,
  onUndoDismiss,
  onBookmarkToggle,
  onReadToggle,
}: ArticleCardProps) {
  return (
    <ArticleCardBase
      article={article}
      index={index}
      categorySlug={categorySlug}
      onArticleClick={isDismissing ? () => onUndoDismiss?.(article) : undefined}
      articleStyle={{
        opacity: isDismissing ? 0.5 : 1,
        cursor: isDismissing ? 'pointer' : undefined,
      }}
      headerActions={
        <button
          type="button"
          className="group/dismiss p-1.5 text-gray-500 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-all duration-200 hover:scale-110"
          title="Dismiss article"
          aria-label="Dismiss article"
          onClick={(event) => {
            event.stopPropagation()
            onDismiss(article)
          }}
        >
          <svg
            className="w-4 h-4 transition-transform group-hover/dismiss:scale-110"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth="2"
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      }
      actions={
        <>
          <button
            type="button"
            className={
              article.bookmarked
                ? 'group/bookmark p-2 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-lg transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-110 hover:shadow-lg hover:shadow-primary-500/25'
                : 'group/bookmark p-2 bg-dark-700 border border-dark-600 text-gray-400 rounded-lg transition-all duration-200 hover:bg-primary-600 hover:border-primary-500 hover:text-white hover:scale-110 hover:shadow-lg hover:shadow-primary-500/25'
            }
            title={article.bookmarked ? 'Remove from reading list' : 'Add to reading list'}
            aria-label={article.bookmarked ? 'Remove from reading list' : 'Add to reading list'}
            onClick={(event) => {
              event.stopPropagation()
              onBookmarkToggle(article)
            }}
          >
            <svg
              className="w-4 h-4 transition-transform group-hover/bookmark:scale-110"
              fill={article.bookmarked ? 'currentColor' : 'none'}
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
              />
            </svg>
          </button>

          <button
            type="button"
            className={
              article.read
                ? 'group/read p-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg transition-all duration-200 hover:from-orange-600 hover:to-orange-700 hover:scale-110 hover:shadow-lg hover:shadow-orange-500/25'
                : 'group/read p-2 bg-dark-700 border border-dark-600 text-gray-400 rounded-lg transition-all duration-200 hover:bg-green-600 hover:border-green-500 hover:text-white hover:scale-110 hover:shadow-lg hover:shadow-green-500/25'
            }
            title={article.read ? 'Mark as unread' : 'Mark as read'}
            aria-label={article.read ? 'Mark as unread' : 'Mark as read'}
            onClick={(event) => {
              event.stopPropagation()
              onReadToggle(article)
            }}
          >
            <svg
              className="w-4 h-4 transition-transform group-hover/read:scale-110"
              fill={article.read ? 'currentColor' : 'none'}
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </button>
        </>
      }
      detailsHref={`/articles/${article.id}`}
    />
  )
}
