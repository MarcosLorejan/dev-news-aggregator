import type { Pagination } from './article'

export interface BookmarkArticle {
  id: number
  title: string
  url: string
  description: string | null
  source_type: string
  score: number
  comment_count: number
  external_id: string
  published_at: string
  bookmarked_at: string | null
  read: boolean
}

export interface BookmarksIndexResponse {
  articles: BookmarkArticle[]
  articles_by_source: Record<string, number[]>
  pagination: Pagination
}
