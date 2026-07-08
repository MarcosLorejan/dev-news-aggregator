import type { BadgeVariant } from '../ui/Badge'

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

export type ArticleCardVariant = 'feed' | 'bookmark' | 'read' | 'dismissed' | 'recent-dismissed'

export type ArticleCardAccent = 'primary' | 'green' | 'orange' | 'red'

export interface CardThemeStyles {
  titleHover: string
  linkHover: string
  borderHover: string
  badgeVariant: BadgeVariant
  detailsHover: string
  dateAccent: string
}

export const CARD_THEMES: Record<ArticleCardTheme, CardThemeStyles> = {
  primary: {
    titleHover: 'group-hover:text-primary-300',
    linkHover: 'hover:text-primary-400',
    borderHover: 'hover:border-primary-500/25',
    badgeVariant: 'primary',
    detailsHover:
      'hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:shadow-primary-500/20',
    dateAccent: 'text-primary-400',
  },
  green: {
    titleHover: 'group-hover:text-green-300',
    linkHover: 'hover:text-green-400',
    borderHover: 'hover:border-green-500/25',
    badgeVariant: 'green',
    detailsHover:
      'hover:from-green-600 hover:to-green-700 hover:border-green-500 hover:shadow-green-500/20',
    dateAccent: 'text-primary-400',
  },
  red: {
    titleHover: 'group-hover:text-red-300',
    linkHover: 'hover:text-red-400',
    borderHover: 'hover:border-red-500/25',
    badgeVariant: 'red',
    detailsHover:
      'hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:shadow-primary-500/20',
    dateAccent: 'text-red-400',
  },
  orange: {
    titleHover: 'group-hover:text-orange-300',
    linkHover: 'hover:text-orange-400',
    borderHover: 'hover:border-orange-500/25',
    badgeVariant: 'orange',
    detailsHover:
      'hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:shadow-primary-500/20',
    dateAccent: 'text-orange-400',
  },
}

export function variantTheme(variant: ArticleCardVariant): ArticleCardTheme {
  switch (variant) {
    case 'read':
      return 'green'
    case 'dismissed':
      return 'red'
    case 'recent-dismissed':
      return 'orange'
    default:
      return 'primary'
  }
}

export function variantBorderClass(variant: ArticleCardVariant): string {
  switch (variant) {
    case 'recent-dismissed':
      return 'border-orange-500/20'
    case 'dismissed':
      return 'border-red-500/20'
    default:
      return ''
  }
}
