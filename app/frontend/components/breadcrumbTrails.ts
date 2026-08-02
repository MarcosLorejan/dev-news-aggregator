import type { BreadcrumbItem } from './Breadcrumbs'

export const feedBreadcrumb: BreadcrumbItem = { label: 'Feed', to: '/' }

export const bookmarksBreadcrumbs: BreadcrumbItem[] = [
  feedBreadcrumb,
  { label: 'Reading List' },
]

export const readArticlesBreadcrumbs: BreadcrumbItem[] = [
  feedBreadcrumb,
  { label: 'Already Read' },
]

export const recentlyDismissedBreadcrumbs: BreadcrumbItem[] = [
  feedBreadcrumb,
  { label: 'Recently Dismissed' },
]

export const allDismissedBreadcrumbs: BreadcrumbItem[] = [
  feedBreadcrumb,
  { label: 'Recently Dismissed', to: '/recently_dismissed' },
  { label: 'All Dismissed' },
]

export const sourcesBreadcrumbs: BreadcrumbItem[] = [
  feedBreadcrumb,
  { label: 'News Sources' },
]

export const interestsBreadcrumbs: BreadcrumbItem[] = [
  feedBreadcrumb,
  { label: 'Interests' },
]

export function articleBreadcrumbs(title: string): BreadcrumbItem[] {
  return [feedBreadcrumb, { label: title }]
}
