import type { CSSProperties, ReactNode } from 'react'
import { truncate } from '../../utils/format'
import { cn } from '../../utils/cn'
import { DetailsLink } from './CardActions'
import CardMetadata from './CardMetadata'
import CardTitle from './CardTitle'
import { CARD_THEMES, type ArticleCardData, type ArticleCardAccent, type ArticleCardTheme } from './cardThemes'

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

      {article.description && (
        <p className="text-body text-gray-200 mb-6 line-clamp-3 leading-relaxed max-w-prose">
          {truncate(article.description, 280)}
        </p>
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
