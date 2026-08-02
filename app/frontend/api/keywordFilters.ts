import { apiRequest } from './client'
import type { KeywordFiltersIndexResponse } from '../types/keywordFilter'

export function fetchKeywordFilters(params?: { signal?: AbortSignal }) {
  return apiRequest<KeywordFiltersIndexResponse>('/keyword_filters.json', {
    signal: params?.signal,
  })
}

export type { KeywordFilter, KeywordFiltersIndexResponse } from '../types/keywordFilter'
