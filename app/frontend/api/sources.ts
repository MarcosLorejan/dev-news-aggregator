import { apiRequest } from './client'

export interface SourceLastFetch {
  status: 'success' | 'failure'
  finished_at: string
  articles_count: number
  duration_seconds: number | null
  error_class: string | null
  error_message: string | null
  empty?: boolean
  success_count?: number
  failure_count?: number
  empty_success_count?: number
  success_rate?: number | null
  last_success_at?: string | null
  last_failure_at?: string | null
  last_article_at?: string | null
}

export interface NewsSource {
  id: number
  name: string
  source_type: 'hacker_news' | 'dev_to' | 'reddit' | 'youtube'
  subreddit: string | null
  channel_id?: string | null
  active: boolean
  last_fetch: SourceLastFetch | null
}

export interface SourcesIndexResponse {
  sources: NewsSource[]
}

export function fetchSources() {
  return apiRequest<SourcesIndexResponse>('/sources.json')
}

export function updateSource(id: number, active: boolean) {
  return apiRequest<NewsSource>(`/sources/${id}.json`, {
    method: 'PATCH',
    body: JSON.stringify({ active }),
  })
}

export function addRedditSource(subreddit: string) {
  return apiRequest<NewsSource>('/sources.json', {
    method: 'POST',
    body: JSON.stringify({ subreddit }),
  })
}

export function removeSource(id: number) {
  return apiRequest<void>(`/sources/${id}.json`, { method: 'DELETE' })
}
