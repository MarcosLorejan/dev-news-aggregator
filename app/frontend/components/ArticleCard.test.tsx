import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import ArticleCard from './ArticleCard'
import type { Article } from '../types/article'

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

const feedArticle: Article = {
  ...baseArticle,
  external_id: 'hn-1',
  created_at: '2024-01-15T10:00:00Z',
  updated_at: '2024-01-15T10:00:00Z',
  bookmarked: false,
  read: false,
  dismissed: false,
  pending_dismissal: false,
}

describe('ArticleCard', () => {
  it('is wrapped in React.memo', () => {
    expect(ArticleCard).toHaveProperty('$$typeof', Symbol.for('react.memo'))
  })

  it('renders feed variant with dismiss and bookmark controls', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={feedArticle}
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

  it('shows a low signal badge when article is flagged', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={{ ...feedArticle, low_signal: true }}
          categorySlug="programming"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    expect(screen.getByText('Low signal')).toBeInTheDocument()
  })

  it('renders related source chips for clustered stories', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={{
            ...feedArticle,
            related_sources: [
              {
                id: 9,
                source_type: 'dev_to',
                url: 'https://example.com/rust',
                title: 'Same story on Dev.to',
                score: 12,
              },
            ],
          }}
          categorySlug="programming"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    expect(screen.getByTestId('related-sources')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Dev To/i })).toHaveAttribute('href', '/articles/9')
  })

  it('renders matched keyword badges with overflow', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={{
            ...feedArticle,
            matched_keywords: ['rust', 'cargo', 'wasm', 'tokio'],
          }}
          categorySlug="programming"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    const badges = screen.getByTestId('matched-keywords')
    expect(badges).toHaveTextContent('rust')
    expect(badges).toHaveTextContent('cargo')
    expect(badges).toHaveTextContent('wasm')
    expect(badges).toHaveTextContent('+1')
    expect(badges).not.toHaveTextContent('tokio')
  })

  it('omits matched keyword badges when the field is absent', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={feedArticle}
          categorySlug="programming"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    expect(screen.queryByTestId('matched-keywords')).not.toBeInTheDocument()
  })

  it('renders video thumbnail, duration badge, and channel name', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={{
            ...feedArticle,
            content_type: 'video',
            title: 'Hexagonal Architecture in Rails',
            author: 'Thoughtbot',
            thumbnail_url: 'https://i.ytimg.com/vi/abc123/hqdefault.jpg',
            duration_seconds: 372,
            source_type: 'youtube_thoughtbot',
          }}
          categorySlug="videos"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    const thumb = screen.getByTestId('video-thumbnail')
    expect(thumb).toHaveAttribute('aria-label', 'Watch Hexagonal Architecture in Rails')
    expect(thumb.querySelector('img')).toHaveAttribute(
      'src',
      'https://i.ytimg.com/vi/abc123/maxresdefault.jpg'
    )
    expect(screen.getByTestId('video-duration')).toHaveTextContent('6:12')
    expect(screen.getByTestId('video-channel')).toHaveTextContent('Thoughtbot')
    expect(screen.getByRole('article')).toHaveAttribute('data-content-type', 'video')
  })

  it('degrades cleanly when thumbnail and duration are missing', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={{
            ...feedArticle,
            content_type: 'video',
            author: 'Confreaks',
            thumbnail_url: null,
            duration_seconds: null,
            source_type: 'youtube_confreaks',
          }}
          categorySlug="videos"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    expect(screen.getByTestId('video-thumbnail')).toBeInTheDocument()
    expect(screen.queryByTestId('video-duration')).not.toBeInTheDocument()
    expect(screen.getByTestId('video-channel')).toHaveTextContent('Confreaks')
    expect(screen.queryByRole('img')).not.toBeInTheDocument()
  })

  it('leaves text articles visually without video chrome', () => {
    render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={{ ...feedArticle, content_type: 'article' }}
          categorySlug="programming"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    expect(screen.queryByTestId('video-thumbnail')).not.toBeInTheDocument()
    expect(screen.queryByTestId('video-channel')).not.toBeInTheDocument()
    expect(screen.getByRole('article')).toHaveAttribute('data-content-type', 'article')
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
