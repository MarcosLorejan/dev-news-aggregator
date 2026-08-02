import { apiRequest } from './client'

export interface DigestSummary {
  id: number
  period: string
  window_start: string
  window_end: string
  payload: {
    period: string
    generated_at: string
    window_start: string
    window_end: string
    themes: Array<{ title: string; summary: string; article_ids: number[] }>
    articles: Array<{
      id: number
      title: string
      url: string
      source_type: string
      score: number | null
      why: string
    }>
  }
  created_at: string
}

export function fetchDigests(signal?: AbortSignal) {
  return apiRequest<{ digests: DigestSummary[] }>('/digests.json', { signal })
}

export function fetchDigest(id: number, signal?: AbortSignal) {
  return apiRequest<DigestSummary>(`/digests/${id}.json`, { signal })
}

export function createDigest(period: 'daily' | 'weekly' = 'daily') {
  return apiRequest<DigestSummary>('/digests', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ period }),
  })
}
