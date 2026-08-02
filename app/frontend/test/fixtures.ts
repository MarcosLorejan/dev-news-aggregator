import type { Article, ArticlesIndexResponse } from '../types/article'
import type { BookmarkArticle, BookmarksIndexResponse } from '../types/bookmark'
import type { NewsSource, SourcesIndexResponse } from '../api/sources'
import type { KeywordFilter, KeywordFiltersIndexResponse } from '../types/keywordFilter'

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
    low_signal: false,
    topic_tags: [],
    related_sources: [],
    summary: null,
    summary_provider: null,
    summarized_at: null,
    summarizer: { enabled: false, provider: 'none' },
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
    category_counts: {
      'Programming Languages': 1,
      Frameworks: 1,
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

export function buildKeywordFilter(overrides: Partial<KeywordFilter> = {}): KeywordFilter {
  return {
    id: 1,
    name: 'Ruby',
    slug: 'ruby',
    terms: ['ruby', 'rubygems'],
    active: true,
    position: 0,
    article_count: 3,
    ...overrides,
  }
}

export function buildKeywordFiltersResponse(
  overrides: Partial<KeywordFiltersIndexResponse> = {}
): KeywordFiltersIndexResponse {
  return {
    keyword_filters: [
      buildKeywordFilter(),
      buildKeywordFilter({
        id: 2,
        name: 'Rust',
        slug: 'rust',
        terms: ['rust'],
        position: 1,
        article_count: 5,
      }),
    ],
    ...overrides,
  }
}

export function buildBookmarkArticle(overrides: Partial<BookmarkArticle> = {}): BookmarkArticle {
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
    bookmarked_at: '2024-06-02T12:00:00Z',
    read: false,
    ...overrides,
  }
}

export function buildBookmarksIndexResponse(
  overrides: Partial<BookmarksIndexResponse> = {}
): BookmarksIndexResponse {
  const first = buildBookmarkArticle()
  const second = buildBookmarkArticle({
    id: 2,
    title: 'Ruby 3.3 Performance Tips',
    source_type: 'reddit_ruby',
  })

  return {
    articles: [first, second],
    articles_by_source: {
      reddit_rust: [first.id],
      reddit_ruby: [second.id],
    },
    pagination: {
      current_page: 1,
      per_page: 20,
      total_count: 2,
      total_pages: 1,
    },
    ...overrides,
  }
}

export function buildNewsSource(overrides: Partial<NewsSource> = {}): NewsSource {
  return {
    id: 1,
    name: 'Hacker News',
    source_type: 'hacker_news',
    subreddit: null,
    active: true,
    last_fetch: null,
    ...overrides,
  }
}

export function buildSourcesIndexResponse(
  overrides: Partial<SourcesIndexResponse> = {}
): SourcesIndexResponse {
  return {
    sources: [
      buildNewsSource(),
      buildNewsSource({
        id: 2,
        name: 'DEV.to',
        source_type: 'dev_to',
        active: false,
      }),
      buildNewsSource({
        id: 3,
        name: 'rust',
        source_type: 'reddit',
        subreddit: 'rust',
        active: true,
      }),
    ],
    ...overrides,
  }
}