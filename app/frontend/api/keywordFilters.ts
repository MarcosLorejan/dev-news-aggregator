import { apiRequest } from './client'
import type { KeywordFilter, KeywordFiltersIndexResponse } from '../types/keywordFilter'

export type KeywordFilterInput = {
  name?: string
  terms?: string[]
  active?: boolean
  position?: number
}

export function fetchKeywordFilters(params?: { signal?: AbortSignal }) {
  return apiRequest<KeywordFiltersIndexResponse>('/keyword_filters.json', {
    signal: params?.signal,
  })
}

export function createKeywordFilter(attributes: KeywordFilterInput) {
  return apiRequest<KeywordFilter>('/keyword_filters.json', {
    method: 'POST',
    body: JSON.stringify({ keyword_filter: attributes }),
  })
}

export function updateKeywordFilter(id: number, attributes: KeywordFilterInput) {
  return apiRequest<KeywordFilter>(`/keyword_filters/${id}.json`, {
    method: 'PATCH',
    body: JSON.stringify({ keyword_filter: attributes }),
  })
}

export function deleteKeywordFilter(id: number) {
  return apiRequest<void>(`/keyword_filters/${id}.json`, { method: 'DELETE' })
}

export type { KeywordFilter, KeywordFiltersIndexResponse } from '../types/keywordFilter'
