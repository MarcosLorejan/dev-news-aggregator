import { apiRequest } from './client'
import type {
  DismissedArticlesIndexResponse,
  RecentlyDismissedResponse,
} from '../types/dismissedArticle'

export function fetchDismissedArticles(params?: { page?: number; per_page?: number }) {
  const search = new URLSearchParams()
  if (params?.page) search.set('page', String(params.page))
  if (params?.per_page) search.set('per_page', String(params.per_page))

  const query = search.toString()
  return apiRequest<DismissedArticlesIndexResponse>(`/dismissed.json${query ? `?${query}` : ''}`)
}

export function fetchRecentlyDismissed() {
  return apiRequest<RecentlyDismissedResponse>('/recently_dismissed.json')
}
