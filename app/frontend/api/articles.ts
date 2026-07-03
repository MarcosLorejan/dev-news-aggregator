import { apiRequest } from './client'
import type { Article, ArticlesIndexResponse } from '../types/article'

export function fetchArticles(params?: { page?: number; per_page?: number; show_read?: boolean }) {
  const search = new URLSearchParams()
  if (params?.page) search.set('page', String(params.page))
  if (params?.per_page) search.set('per_page', String(params.per_page))
  if (params?.show_read) search.set('show_read', 'true')

  const query = search.toString()
  return apiRequest<ArticlesIndexResponse>(`/articles.json${query ? `?${query}` : ''}`)
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
