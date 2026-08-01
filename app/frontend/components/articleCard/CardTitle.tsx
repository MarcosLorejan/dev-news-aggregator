import type { MouseEvent, ReactNode } from 'react'
import { humanizeSourceType } from '../../utils/format'
import Badge from '../ui/Badge'
import type { ArticleCardData, CardThemeStyles } from './cardThemes'

interface CardTitleProps {
  article: ArticleCardData
  styles: CardThemeStyles
  badge?: ReactNode
  showSourceBadge?: boolean
  headerActions?: ReactNode
}

function stopPropagation(event: MouseEvent) {
  event.stopPropagation()
}

export default function CardTitle({
  article,
  styles,
  badge,
  showSourceBadge = true,
  headerActions,
}: CardTitleProps) {
  return (
    <div className="flex justify-between items-start mb-4">
      <div className="flex-1">
        <h2
          className={`text-h3 font-semibold text-gray-50 mb-2 leading-snug ${styles.titleHover} transition-colors duration-200`}
        >
          <a
            href={article.url}
            target="_blank"
            rel="noopener noreferrer"
            className={`${styles.linkHover} transition-colors duration-200 flex items-start group/link`}
            onClick={stopPropagation}
          >
            <span className="flex-1">{article.title}</span>
            <svg
              className="w-4 h-4 ml-2 mt-1 opacity-60 group-hover/link:opacity-100 transition-all duration-200 group-hover/link:translate-x-1"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              aria-hidden="true"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
              />
            </svg>
          </a>
        </h2>
      </div>
      <div className="ml-4 flex items-center space-x-2">
        {badge}
        {article.low_signal && !badge && (
          <Badge variant="orange">Low signal</Badge>
        )}
        {showSourceBadge && !badge && (
          <Badge variant={styles.badgeVariant}>{humanizeSourceType(article.source_type)}</Badge>
        )}
        {headerActions}
      </div>
    </div>
  )
}
