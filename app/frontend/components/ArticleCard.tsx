import type { Article } from '../types/article'
import type { BookmarkArticle } from '../types/bookmark'
import type { DismissedArticle } from '../types/dismissedArticle'
import type { ReadArticle } from '../types/readArticle'
import { formatBookmarkedDate, formatTimeAgo } from '../utils/format'
import { useConfirmDialog } from '../hooks/useConfirmDialog'
import ArticleCardLayout from './articleCard/ArticleCardLayout'
import {
  BookmarkButton,
  DismissButton,
  ReadButton,
  RestoreButton,
} from './articleCard/CardActions'
import { variantBorderClass, variantTheme, type ArticleCardVariant } from './articleCard/cardThemes'
import Badge from './ui/Badge'

type FeedCardProps = {
  variant: 'feed'
  article: Article
  categorySlug: string
  index: number
  isDismissing: boolean
  onDismiss: (article: Article) => void
  onUndoDismiss?: (article: Article) => void
  onBookmarkToggle: (article: Article) => void
  onReadToggle: (article: Article) => void
}

type BookmarkCardProps = {
  variant: 'bookmark'
  article: BookmarkArticle
  index: number
  onRemoveBookmark: (article: BookmarkArticle) => void
  onReadToggle: (article: BookmarkArticle) => void
}

type ReadCardProps = {
  variant: 'read'
  article: ReadArticle
  index: number
  onUnmarkRead: (article: ReadArticle) => void
}

type DismissedCardProps = {
  variant: 'dismissed' | 'recent-dismissed'
  article: DismissedArticle
  index: number
  onRestore: (article: DismissedArticle) => void
}

export type ArticleCardProps = FeedCardProps | BookmarkCardProps | ReadCardProps | DismissedCardProps

export default function ArticleCard(props: ArticleCardProps) {
  const { confirm, dialog } = useConfirmDialog()
  const { variant, article, index } = props
  const theme = variantTheme(variant)
  const detailsHref = `/articles/${article.id}`

  if (variant === 'feed') {
    const { categorySlug, isDismissing, onDismiss, onUndoDismiss, onBookmarkToggle, onReadToggle } =
      props
    return (
      <ArticleCardLayout
        article={article}
        index={index}
        theme={theme}
        categorySlug={categorySlug}
        onArticleClick={isDismissing ? () => onUndoDismiss?.(article) : undefined}
        articleStyle={{
          opacity: isDismissing ? 0.5 : 1,
          cursor: isDismissing ? 'pointer' : undefined,
        }}
        headerActions={<DismissButton onClick={() => onDismiss(article)} />}
        actions={
          <>
            <BookmarkButton
              active={article.bookmarked}
              mode="toggle"
              onClick={() => onBookmarkToggle(article)}
            />
            <ReadButton
              active={article.read}
              mode="toggle"
              onClick={() => onReadToggle(article)}
            />
          </>
        }
        detailsHref={detailsHref}
      />
    )
  }

  if (variant === 'bookmark') {
    const { onRemoveBookmark, onReadToggle } = props
    const handleRemove = async () => {
      const confirmed = await confirm({
        message: 'Remove this article from your reading list?',
        confirmLabel: 'Remove',
      })
      if (confirmed) onRemoveBookmark(article)
    }

    return (
      <>
        <ArticleCardLayout
          article={article}
          index={index}
          theme={theme}
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
              <ReadButton
                active={article.read}
                mode="toggle"
                onClick={() => onReadToggle(article)}
              />
              <BookmarkButton active mode="remove" onClick={handleRemove} />
            </>
          }
          detailsHref={detailsHref}
        />
        {dialog}
      </>
    )
  }

  if (variant === 'read') {
    const { onUnmarkRead } = props
    const handleUnmark = async () => {
      const confirmed = await confirm({
        message: 'Mark this article as unread?',
        confirmLabel: 'Mark unread',
        confirmTone: 'primary',
      })
      if (confirmed) onUnmarkRead(article)
    }

    return (
      <>
        <ArticleCardLayout
          article={article}
          index={index}
          theme={theme}
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
          actions={<ReadButton active mode="unmark" onClick={handleUnmark} />}
          detailsHref={detailsHref}
        />
        {dialog}
      </>
    )
  }

  const isRecent = variant === 'recent-dismissed'
  const { onRestore } = props
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
      <ArticleCardLayout
        article={article}
        index={index}
        theme={theme}
        borderClass={variantBorderClass(variant)}
        showSourceBadge={false}
        badge={<Badge variant={isRecent ? 'orange' : 'red'}>{badgeText}</Badge>}
        actions={<RestoreButton label={restoreLabel} onClick={handleRestore} />}
      />
      {dialog}
    </>
  )
}

export type { ArticleCardData } from './articleCard/cardThemes'
