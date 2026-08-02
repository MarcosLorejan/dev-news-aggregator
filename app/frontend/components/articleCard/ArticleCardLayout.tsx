import type { CSSProperties, ReactNode } from 'react'
import { humanizeSourceType, truncate } from '../../utils/format'
import { cn } from '../../utils/cn'
import { DetailsLink } from './CardActions'
import CardMetadata from './CardMetadata'
import CardTitle from './CardTitle'
import VideoThumbnail from './VideoThumbnail'
import Badge from '../ui/Badge'
import { CARD_THEMES, type ArticleCardData, type ArticleCardAccent, type ArticleCardTheme } from './cardThemes'

const MATCHED_KEYWORD_LIMIT = 3

interface ArticleCardLayoutProps {
  article: ArticleCardData
  index: number
  theme?: ArticleCardTheme
  categorySlug?: string
  borderClass?: string
  badge?: ReactNode
  showSourceBadge?: boolean
  headerActions?: ReactNode
  extraMetadata?: ReactNode
  actions?: ReactNode
  detailsHref?: string
  onArticleClick?: () => void
  articleStyle?: CSSProperties
  accentBar?: ArticleCardAccent
  featured?: boolean
}

const ACCENT_BAR_CLASSES: Record<NonNullable<ArticleCardAccent>, string> = {
  primary: 'border-l-[3px] border-l-primary-500/70',
  green: 'border-l-[3px] border-l-green-500/70',
  orange: 'border-l-[3px] border-l-orange-500/70',
  red: 'border-l-[3px] border-l-red-500/70',
}

function MatchedKeywordBadges({ keywords }: { keywords: string[] }) {
  const visible = keywords.slice(0, MATCHED_KEYWORD_LIMIT)
  const overflow = keywords.length - visible.length

  return (
    <div className="mb-5 flex flex-wrap items-center gap-2" data-testid="matched-keywords">
      {visible.map((keyword) => (
        <Badge key={keyword} variant="primary" size="sm">
          {keyword}
        </Badge>
      ))}
      {overflow > 0 && (
        <Badge variant="orange" size="sm">
          +{overflow}
        </Badge>
      )}
    </div>
  )
}

export default function ArticleCardLayout({
  article,
  index,
  theme = 'primary',
  categorySlug,
  borderClass = '',
  badge,
  showSourceBadge = true,
  headerActions,
  extraMetadata,
  actions,
  detailsHref,
  onArticleClick,
  articleStyle,
  accentBar,
  featured = false,
}: ArticleCardLayoutProps) {
  const styles = CARD_THEMES[theme]
  const relatedSources = article.related_sources ?? []
  const matchedKeywords = article.matched_keywords ?? []
  const isVideo = article.content_type === 'video'

  return (
    <article
      className={cn(
        'article-card group surface-card rounded-2xl transition-colors duration-200 motion-safe:animate-fade-in motion-sensitive',
        featured ? 'p-7 md:p-8' : 'p-6',
        accentBar && ACCENT_BAR_CLASSES[accentBar],
        accentBar && 'pl-5',
        styles.borderHover,
        borderClass
      )}
      data-source={article.source_type}
      data-category={categorySlug}
      data-content-type={article.content_type ?? 'article'}
      data-featured={featured || undefined}
      style={{
        animationDelay: `${index * 50}ms`,
        ...articleStyle,
      }}
      onClick={onArticleClick}
    >
      <CardTitle
        article={article}
        styles={styles}
        badge={badge}
        showSourceBadge={showSourceBadge}
        headerActions={headerActions}
      />

      {isVideo && (
        <VideoThumbnail
          title={article.title}
          url={article.url}
          thumbnailUrl={article.thumbnail_url}
          durationSeconds={article.duration_seconds}
        />
      )}

      {isVideo && article.author && (
        <p className="mb-4 text-sm text-gray-300" data-testid="video-channel">
          {article.author}
        </p>
      )}

      {article.description && (
        <p className="text-body text-gray-200 mb-6 line-clamp-3 leading-relaxed max-w-prose">
          {truncate(article.description, 280)}
        </p>
      )}

      {matchedKeywords.length > 0 && <MatchedKeywordBadges keywords={matchedKeywords} />}

      {relatedSources.length > 0 && (
        <div className="mb-5 flex flex-wrap items-center gap-2" data-testid="related-sources">
          <span className="text-caption text-gray-400">Also on</span>
          {relatedSources.map((related) => (
            <a
              key={related.id}
              href={`/articles/${related.id}`}
              className="text-caption rounded-md border border-dark-500 px-2 py-1 text-gray-200 hover:border-primary-500/40 hover:text-primary-300 transition-colors"
              onClick={(event) => event.stopPropagation()}
            >
              {humanizeSourceType(related.source_type)}
            </a>
          ))}
        </div>
      )}

      <div className="flex justify-between items-center text-caption text-gray-300 border-t border-dark-600 pt-4">
        <CardMetadata article={article} styles={styles} extra={extraMetadata} />
        <div className="flex items-center space-x-3">
          {actions}
          {detailsHref && <DetailsLink href={detailsHref} styles={styles} />}
        </div>
      </div>
    </article>
  )
}

export { CARD_THEMES }
