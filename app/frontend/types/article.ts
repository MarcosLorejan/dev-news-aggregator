export interface Article {
  id: number
  title: string
  url: string
  description: string | null
  source_type: string
  score: number
  comment_count: number
  external_id: string
  published_at: string
  created_at: string
  updated_at: string
  bookmarked: boolean
  read: boolean
  dismissed: boolean
  pending_dismissal: boolean
}

export interface Category {
  name: string
  icon: string
}

export interface Pagination {
  current_page: number
  per_page: number
  total_count: number
  total_pages: number
}

export interface ArticlesIndexResponse {
  articles: Article[]
  articles_by_category: Record<string, number[]>
  categories: Category[]
  pagination: Pagination
  last_updated: string | null
}
