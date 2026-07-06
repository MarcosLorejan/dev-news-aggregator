import type { BookmarkArticle } from '../types/bookmark'
import { formatBookmarkedDate } from '../utils/format'
import { useConfirmDialog } from '../hooks/useConfirmDialog'
import ArticleCardBase from './ArticleCardBase'

interface BookmarkCardProps {
  article: BookmarkArticle
  index: number
  onRemoveBookmark: (article: BookmarkArticle) => void
  onReadToggle: (article: BookmarkArticle) => void
}

export default function BookmarkCard({
  article,
  index,
  onRemoveBookmark,
  onReadToggle,
}: BookmarkCardProps) {
  const { confirm, dialog } = useConfirmDialog()

  const handleRemove = async () => {
    const confirmed = await confirm({
      message: 'Remove this article from your reading list?',
      confirmLabel: 'Remove',
    })
    if (confirmed) {
      onRemoveBookmark(article)
    }
  }

  return (
    <>
      <ArticleCardBase
        article={article}
        index={index}
        extraMetadata={
          article.bookmarked_at ? (
            <span className="flex items-center text-primary-400">
              <svg className="w-4 h-4 mr-1.5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
              </svg>
              Bookmarked {formatBookmarkedDate(article.bookmarked_at)}
            </span>
          ) : undefined
        }
        actions={
          <>
            <button
              type="button"
              className={
                article.read
                  ? 'group/read p-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg transition-all duration-200 hover:from-orange-600 hover:to-orange-700 hover:scale-110 hover:shadow-lg hover:shadow-orange-500/25'
                  : 'group/read p-2 bg-dark-700 border border-dark-600 text-gray-400 rounded-lg transition-all duration-200 hover:bg-green-600 hover:border-green-500 hover:text-white hover:scale-110 hover:shadow-lg hover:shadow-green-500/25'
              }
              title={article.read ? 'Mark as unread' : 'Mark as read'}
              aria-label={article.read ? 'Mark as unread' : 'Mark as read'}
              onClick={() => onReadToggle(article)}
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

            <button
              type="button"
              className="group/bookmark p-2 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg transition-all duration-200 hover:from-red-700 hover:to-red-800 hover:scale-110 hover:shadow-lg hover:shadow-red-500/25"
              title="Remove from reading list"
              aria-label="Remove from reading list"
              onClick={handleRemove}
            >
              <svg
                className="w-4 h-4 transition-transform group-hover/bookmark:scale-110"
                fill="currentColor"
                viewBox="0 0 24 24"
              >
                <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
              </svg>
            </button>
          </>
        }
        detailsHref={`/articles/${article.id}`}
      />
      {dialog}
    </>
  )
}
