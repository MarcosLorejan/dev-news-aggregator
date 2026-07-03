import { apiRequest } from './client'
import type { ReadArticlesIndexResponse } from '../types/readArticle'

export function fetchReadArticles(params?: { page?: number; per_page?: number }) {
  const search = new URLSearchParams()
  if (params?.page) search.set('page', String(params.page))
  if (params?.per_page) search.set('per_page', String(params.per_page))

  const query = search.toString()
  return apiRequest<ReadArticlesIndexResponse>(`/read.json${query ? `?${query}` : ''}`)
}
