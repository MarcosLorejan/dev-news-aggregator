import type { DismissedArticle } from '../types/dismissedArticle'
import { formatBookmarkedDate, formatTimeAgo } from '../utils/format'
import { useConfirmDialog } from '../hooks/useConfirmDialog'
import ArticleCardBase from './ArticleCardBase'
import Badge from './ui/Badge'
import Button from './ui/Button'

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
  const { confirm, dialog } = useConfirmDialog()
  const isRecent = variant === 'recent'
  const theme = isRecent ? 'orange' : 'red'
  const borderClass = isRecent ? 'border-orange-500/20' : 'border-red-500/20'
  const restoreLabel = isRecent ? 'Quick Restore' : 'Restore'

  const handleRestore = async () => {
    if (!isRecent) {
      const confirmed = await confirm({
        message: 'Restore this article to your main feed?',
        confirmLabel: 'Restore',
        confirmTone: 'primary',
      })
      if (!confirmed) return
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

  return (
    <>
      <ArticleCardBase
        article={article}
        index={index}
        theme={theme}
        borderClass={borderClass}
        showSourceBadge={false}
        badge={<Badge variant={isRecent ? 'orange' : 'red'}>{badgeText}</Badge>}
        actions={
          <Button color="green" size="sm" className="group/restore" title="Restore article" onClick={handleRestore}>
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
          </Button>
        }
      />
      {dialog}
    </>
  )
}
