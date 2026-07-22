import { apiRequest } from './client'
import type {
  DismissedArticlesIndexResponse,
  RecentlyDismissedResponse,
} from '../types/dismissedArticle'

export function fetchDismissedArticles(params?: {
  page?: number
  per_page?: number
  signal?: AbortSignal
}) {
  const search = new URLSearchParams()
  if (params?.page) search.set('page', String(params.page))
  if (params?.per_page) search.set('per_page', String(params.per_page))

  const query = search.toString()
  return apiRequest<DismissedArticlesIndexResponse>(`/dismissed.json${query ? `?${query}` : ''}`, {
    signal: params?.signal,
  })
}

export function fetchRecentlyDismissed(params?: { signal?: AbortSignal }) {
  return apiRequest<RecentlyDismissedResponse>('/recently_dismissed.json', {
    signal: params?.signal,
  })
}
