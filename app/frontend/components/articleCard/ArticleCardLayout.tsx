import type { CSSProperties, ReactNode } from 'react'
import { truncate } from '../../utils/format'
import { cn } from '../../utils/cn'
import { DetailsLink } from './CardActions'
import CardMetadata from './CardMetadata'
import CardTitle from './CardTitle'
import { CARD_THEMES, type ArticleCardData, type ArticleCardTheme } from './cardThemes'

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
}: ArticleCardLayoutProps) {
  const styles = CARD_THEMES[theme]

  return (
    <article
      className={cn(
        'article-card group glass-effect rounded-2xl p-6 transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl animate-fade-in',
        styles.shadowHover,
        borderClass
      )}
      data-source={article.source_type}
      data-category={categorySlug}
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
        <p className="text-gray-400 mb-6 line-clamp-3 leading-relaxed">
          {truncate(article.description, 280)}
        </p>
      )}

      <div className="flex justify-between items-center text-sm border-t border-dark-700 pt-4">
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
