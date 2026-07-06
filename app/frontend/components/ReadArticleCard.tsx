import type { ReadArticle } from '../types/readArticle'
import { formatBookmarkedDate } from '../utils/format'
import { useConfirmDialog } from '../hooks/useConfirmDialog'
import ArticleCardBase from './ArticleCardBase'

interface ReadArticleCardProps {
  article: ReadArticle
  index: number
  onUnmarkRead: (article: ReadArticle) => void
}

export default function ReadArticleCard({ article, index, onUnmarkRead }: ReadArticleCardProps) {
  const { confirm, dialog } = useConfirmDialog()

  const handleUnmark = async () => {
    const confirmed = await confirm({
      message: 'Mark this article as unread?',
      confirmLabel: 'Mark unread',
      confirmTone: 'primary',
    })
    if (confirmed) {
      onUnmarkRead(article)
    }
  }

  return (
    <>
      <ArticleCardBase
        article={article}
        index={index}
        theme="green"
        extraMetadata={
          article.read_at ? (
            <span className="flex items-center text-green-400">
              <svg className="w-4 h-4 mr-1.5" fill="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Read {formatBookmarkedDate(article.read_at)}
            </span>
          ) : undefined
        }
        actions={
          <button
            type="button"
            className="group/read p-2 bg-gradient-to-r from-orange-600 to-orange-700 text-white rounded-lg transition-all duration-200 hover:from-orange-700 hover:to-orange-800 hover:scale-110 hover:shadow-lg hover:shadow-orange-500/25"
            title="Mark as unread"
            aria-label="Mark as unread"
            onClick={handleUnmark}
          >
            <svg
              className="w-4 h-4 transition-transform group-hover/read:scale-110"
              fill="none"
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
        }
        detailsHref={`/articles/${article.id}`}
      />
      {dialog}
    </>
  )
}
