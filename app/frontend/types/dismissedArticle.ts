export interface DismissedArticle {
  id: number
  title: string
  url: string
  description: string | null
  source_type: string
  score: number
  comment_count: number
  external_id: string
  published_at: string
  dismissed_at: string | null
  permanent: boolean | null
}

export interface DismissedArticlesIndexResponse {
  articles: DismissedArticle[]
  pagination: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

export interface RecentlyDismissedResponse {
  articles: DismissedArticle[]
}
