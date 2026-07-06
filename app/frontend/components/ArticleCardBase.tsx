import type { CSSProperties, MouseEvent, ReactNode } from 'react'
import { Link } from 'react-router-dom'
import {
  formatPublishedDate,
  humanizeSourceType,
  truncate,
} from '../utils/format'
import Badge, { type BadgeVariant } from './ui/Badge'
import { cn } from '../utils/cn'

export interface ArticleCardData {
  id: number
  title: string
  url: string
  description: string | null
  source_type: string
  score: number
  comment_count: number
  published_at: string
}

export type ArticleCardTheme = 'primary' | 'green' | 'red' | 'orange'

const CARD_THEMES: Record<
  ArticleCardTheme,
  {
    titleHover: string
    linkHover: string
    shadowHover: string
    badgeVariant: BadgeVariant
    detailsHover: string
    dateAccent: string
  }
> = {
  primary: {
    titleHover: 'group-hover:text-primary-300',
    linkHover: 'hover:text-primary-400',
    shadowHover: 'hover:shadow-primary-500/10',
    badgeVariant: 'primary',
    detailsHover:
      'hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:shadow-primary-500/20',
    dateAccent: 'text-primary-400',
  },
  green: {
    titleHover: 'group-hover:text-green-300',
    linkHover: 'hover:text-green-400',
    shadowHover: 'hover:shadow-green-500/10',
    badgeVariant: 'green',
    detailsHover:
      'hover:from-green-600 hover:to-green-700 hover:border-green-500 hover:shadow-green-500/20',
    dateAccent: 'text-primary-400',
  },
  red: {
    titleHover: 'group-hover:text-red-300',
    linkHover: 'hover:text-red-400',
    shadowHover: 'hover:shadow-red-500/10',
    badgeVariant: 'red',
    detailsHover:
      'hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:shadow-primary-500/20',
    dateAccent: 'text-red-400',
  },
  orange: {
    titleHover: 'group-hover:text-orange-300',
    linkHover: 'hover:text-orange-400',
    shadowHover: 'hover:shadow-orange-500/10',
    badgeVariant: 'orange',
    detailsHover:
      'hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:shadow-primary-500/20',
    dateAccent: 'text-orange-400',
  },
}

interface ArticleCardBaseProps {
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

function stopPropagation(event: MouseEvent) {
  event.stopPropagation()
}

export default function ArticleCardBase({
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
}: ArticleCardBaseProps) {
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
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h2
            className={`text-xl font-bold text-gray-100 mb-2 leading-tight ${styles.titleHover} transition-colors duration-200`}
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
          {showSourceBadge && !badge && (
            <Badge variant={styles.badgeVariant}>{humanizeSourceType(article.source_type)}</Badge>
          )}
          {headerActions}
        </div>
      </div>

      {article.description && (
        <p className="text-gray-400 mb-6 line-clamp-3 leading-relaxed">
          {truncate(article.description, 280)}
        </p>
      )}

      <div className="flex justify-between items-center text-sm border-t border-dark-700 pt-4">
        <div className="flex items-center space-x-6 text-gray-500">
          <span className="flex items-center">
            <svg
              className={`w-4 h-4 mr-1.5 ${styles.dateAccent}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
            {formatPublishedDate(article.published_at)}
          </span>
          <span className="flex items-center">
            <svg
              className="w-4 h-4 mr-1.5 text-green-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5"
              />
            </svg>
            {article.score}
          </span>
          <span className="flex items-center">
            <svg
              className="w-4 h-4 mr-1.5 text-blue-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
            {article.comment_count}
          </span>
          {extraMetadata}
        </div>

        <div className="flex items-center space-x-3">
          {actions}
          {detailsHref && (
            <Link
              to={detailsHref}
              className={`group/detail px-4 py-2 bg-gradient-to-r from-dark-700 to-dark-600 border border-dark-500 text-gray-300 rounded-lg font-medium transition-all duration-200 ${styles.detailsHover} hover:text-white hover:scale-105 hover:shadow-lg`}
              onClick={stopPropagation}
            >
              <span className="flex items-center">
                Details
                <svg
                  className="w-4 h-4 ml-2 transition-transform group-hover/detail:translate-x-1"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </span>
            </Link>
          )}
        </div>
      </div>
    </article>
  )
}
