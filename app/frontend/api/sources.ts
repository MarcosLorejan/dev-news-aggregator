import { apiRequest } from './client'

export interface NewsSource {
  id: number
  name: string
  source_type: 'hacker_news' | 'dev_to' | 'reddit'
  subreddit: string | null
  active: boolean
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
