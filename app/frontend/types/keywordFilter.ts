export interface KeywordFilter {
  id: number
  name: string
  slug: string
  terms: string[]
  active: boolean
  position: number
  article_count: number | null
}

export interface KeywordFiltersIndexResponse {
  keyword_filters: KeywordFilter[]
}
