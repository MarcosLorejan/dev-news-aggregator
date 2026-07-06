import type { Article, ArticlesIndexResponse } from '../types/article'

export function buildArticle(overrides: Partial<Article> = {}): Article {
  return {
    id: 1,
    title: 'Rust 2024 Edition Highlights',
    url: 'https://example.com/rust',
    description: 'A summary of Rust changes.',
    source_type: 'reddit_rust',
    score: 120,
    comment_count: 8,
    external_id: 'rust-1',
    published_at: '2024-06-01T12:00:00Z',
    created_at: '2024-06-01T12:00:00Z',
    updated_at: '2024-06-01T12:00:00Z',
    bookmarked: false,
    read: false,
    dismissed: false,
    pending_dismissal: false,
    ...overrides,
  }
}

export function buildArticlesIndexResponse(
  overrides: Partial<ArticlesIndexResponse> = {}
): ArticlesIndexResponse {
  const first = buildArticle()
  const second = buildArticle({
    id: 2,
    title: 'Ruby 3.3 Performance Tips',
    source_type: 'reddit_ruby',
  })

  return {
    articles: [first, second],
    articles_by_category: {
      'Programming Languages': [first.id],
      Frameworks: [second.id],
    },
    categories: [
      { name: 'Programming Languages', icon: '🔨' },
      { name: 'Frameworks', icon: '🧱' },
    ],
    pagination: {
      current_page: 1,
      per_page: 20,
      total_count: 2,
      total_pages: 1,
    },
    last_updated: '2024-06-01T12:00:00Z',
    ...overrides,
  }
}
