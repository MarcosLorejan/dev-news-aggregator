import { apiRequest } from './client'
import type { Article, ArticlesIndexResponse } from '../types/article'

export function fetchArticles(params?: {
  page?: number
  per_page?: number
  show_read?: boolean
  category?: string
  q?: string
  min_score?: number
  top_percent?: number
  signal?: AbortSignal
}) {
  const search = new URLSearchParams()
  if (params?.page) search.set('page', String(params.page))
  if (params?.per_page) search.set('per_page', String(params.per_page))
  if (params?.show_read) search.set('show_read', 'true')
  if (params?.category && params.category !== 'all') search.set('category', params.category)
  if (params?.q?.trim()) search.set('q', params.q.trim())
  if (params?.min_score) search.set('min_score', String(params.min_score))
  if (params?.top_percent) search.set('top_percent', String(params.top_percent))

  const query = search.toString()
  return apiRequest<ArticlesIndexResponse>(`/articles.json${query ? `?${query}` : ''}`, {
    signal: params?.signal,
  })
}

export interface FetchNewsResponse {
  status: string
  job_id: string
}

export function fetchNews() {
  return apiRequest<FetchNewsResponse>('/articles/fetch', { method: 'POST' })
}

export function fetchArticle(id: number) {
  return apiRequest<Article>(`/articles/${id}.json`)
}

export function bookmarkArticle(id: number) {
  return apiRequest<{ bookmarked: boolean }>(`/articles/${id}/bookmark`, { method: 'POST' })
}

export function unbookmarkArticle(id: number) {
  return apiRequest<{ bookmarked: boolean }>(`/articles/${id}/unbookmark`, { method: 'DELETE' })
}

export function markArticleAsRead(id: number) {
  return apiRequest<{ read: boolean }>(`/articles/${id}/mark_as_read`, { method: 'POST' })
}

export function unmarkArticleAsRead(id: number) {
  return apiRequest<{ read: boolean }>(`/articles/${id}/unmark_as_read`, { method: 'DELETE' })
}

export function dismissArticle(id: number) {
  return apiRequest<{ status: string; timeout: number }>(`/articles/${id}/dismiss`, { method: 'POST' })
}

export function undismissArticle(id: number) {
  return apiRequest<{ status: string }>(`/articles/${id}/undismiss`, { method: 'DELETE' })
}

export type { Article }
