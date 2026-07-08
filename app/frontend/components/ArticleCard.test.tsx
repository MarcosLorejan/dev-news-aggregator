import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import ArticleCard from './ArticleCard'

const baseArticle = {
  id: 1,
  title: 'Rust 2024 Edition Highlights',
  url: 'https://example.com/rust',
  description: 'A summary of Rust changes.',
  source_type: 'hacker_news',
  score: 42,
  comment_count: 7,
  published_at: '2024-01-15T10:00:00Z',
}

describe('ArticleCard', () => {
  it('renders feed variant with dismiss and bookmark controls', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={{ ...baseArticle, bookmarked: false, read: false }}
          categorySlug="programming"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    expect(screen.getByRole('article')).toHaveClass('article-card')
    expect(screen.getByLabelText('Dismiss article')).toBeInTheDocument()
    expect(screen.getByLabelText('Add to reading list')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Details/i })).toHaveAttribute('href', '/articles/1')
  })

  it('renders bookmark variant with bookmarked metadata', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="bookmark"
          article={{
            ...baseArticle,
            external_id: 'hn-1',
            bookmarked_at: '2024-01-16T10:00:00Z',
            read: false,
          }}
          index={0}
          onRemoveBookmark={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    expect(screen.getByText(/Bookmarked/)).toBeInTheDocument()
    expect(screen.getByLabelText('Remove from reading list')).toBeInTheDocument()
  })

  it('renders dismissed variant with restore action', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="dismissed"
          article={{
            ...baseArticle,
            external_id: 'hn-1',
            dismissed_at: '2024-01-16T10:00:00Z',
            permanent: false,
          }}
          index={0}
          onRestore={() => {}}
        />
      </MemoryRouter>
    )

    expect(screen.getByRole('button', { name: 'Restore' })).toBeInTheDocument()
    expect(screen.getByText(/Dismissed/)).toBeInTheDocument()
  })
})
