import { render } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'
import { axe } from 'vitest-axe'
import ArticleCard from './ArticleCard'
import CategoryFilter from './CategoryFilter'
import ConfirmDialog from './ConfirmDialog'
import PageHeading from './ui/PageHeading'

const baseArticle = {
  id: 1,
  title: 'Rust 2024 Edition Highlights',
  url: 'https://example.com/rust',
  description: 'A summary of Rust changes.',
  source_type: 'hacker_news',
  score: 42,
  comment_count: 7,
  published_at: '2024-01-15T10:00:00Z',
  external_id: 'hn-1',
  created_at: '2024-01-15T10:00:00Z',
  updated_at: '2024-01-15T10:00:00Z',
  bookmarked: false,
  read: false,
  dismissed: false,
  pending_dismissal: false,
}

describe('accessibility audits', () => {
  it('CategoryFilter has no critical accessibility violations', async () => {
    const { container } = render(
      <CategoryFilter
        categories={[
          { name: 'Programming Languages', icon: '🔨' },
          { name: 'Frameworks', icon: '🧱' },
        ]}
        categoryCounts={{ 'Programming Languages': 3, Frameworks: 1 }}
        totalCount={4}
        activeFilter="all"
        onFilterChange={vi.fn()}
      />
    )

    const results = await axe(container)
    expect(results).toHaveNoViolations()
  })

  it('feed ArticleCard has no critical accessibility violations', async () => {
    const { container } = render(
      <MemoryRouter>
        <ArticleCard
          variant="feed"
          article={baseArticle}
          categorySlug="programming-languages"
          index={0}
          isDismissing={false}
          onDismiss={() => {}}
          onBookmarkToggle={() => {}}
          onReadToggle={() => {}}
        />
      </MemoryRouter>
    )

    const results = await axe(container)
    expect(results).toHaveNoViolations()
  })

  it('PageHeading has no critical accessibility violations', async () => {
    const { container } = render(
      <PageHeading title="Reading List" subtitle="Bookmarked articles" />
    )

    const results = await axe(container)
    expect(results).toHaveNoViolations()
  })

  it('ConfirmDialog has no critical accessibility violations when open', async () => {
    const { container } = render(
      <ConfirmDialog
        open
        title="Remove bookmark"
        message="Remove this article from your reading list?"
        confirmLabel="Remove"
        onConfirm={() => {}}
        onCancel={() => {}}
      />
    )

    const results = await axe(container)
    expect(results).toHaveNoViolations()
  })
})

describe('keyboard focus', () => {
  it('exposes visible focus styles on primary buttons', async () => {
    const user = userEvent.setup()
    const { container } = render(
      <CategoryFilter
        categories={[{ name: 'Frameworks', icon: '🧱' }]}
        categoryCounts={{ Frameworks: 1 }}
        totalCount={1}
        activeFilter="all"
        onFilterChange={vi.fn()}
      />
    )

    await user.tab()
    const focused = container.querySelector(':focus')
    expect(focused?.className).toMatch(/focus-visible:ring-primary-500|ring-primary-500/)
  })
})
