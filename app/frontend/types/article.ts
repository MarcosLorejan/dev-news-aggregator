export interface TopicTag {
  slug: string
  name: string
}

export interface RelatedSource {
  id: number
  source_type: string
  url: string
  title: string
  score: number | null
}

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
  low_signal?: boolean
  topic_tags?: TopicTag[]
  related_sources?: RelatedSource[]
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
  category_counts: Record<string, number>
  categories: Category[]
  topic_tags?: TopicTag[]
  pagination: Pagination
  last_updated: string | null
}
