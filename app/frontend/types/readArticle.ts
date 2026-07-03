export interface ReadArticle {
  id: number
  title: string
  url: string
  description: string | null
  source_type: string
  score: number
  comment_count: number
  external_id: string
  published_at: string
  read_at: string | null
  bookmarked: boolean
}

export interface ReadArticlesIndexResponse {
  articles: ReadArticle[]
  articles_by_source: Record<string, number[]>
  pagination: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}
