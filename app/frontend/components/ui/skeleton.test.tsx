import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import ArticleListSkeleton from '../ArticleListSkeleton'
import ArticleShowSkeleton from '../ArticleShowSkeleton'
import { Skeleton } from './Skeleton'

describe('Skeleton', () => {
  it('renders a pulse placeholder on dark-700', () => {
    const { container } = render(<Skeleton className="h-4 w-24" />)
    const element = container.firstChild as HTMLElement
    expect(element.className).toContain('bg-dark-700')
    expect(element.className).toContain('motion-safe:animate-pulse')
    expect(element).toHaveAttribute('aria-hidden', 'true')
  })
})

describe('ArticleListSkeleton', () => {
  it('renders six card skeletons with an accessible loading label', () => {
    render(<ArticleListSkeleton />)
    expect(screen.getByTestId('article-list-skeleton')).toBeInTheDocument()
    expect(screen.getAllByTestId('article-card-skeleton')).toHaveLength(6)
    expect(screen.getByText('Loading articles')).toHaveClass('sr-only')
  })

  it('supports a custom card count', () => {
    render(<ArticleListSkeleton count={8} label="Loading bookmarks" />)
    expect(screen.getAllByTestId('article-card-skeleton')).toHaveLength(8)
    expect(screen.getByText('Loading bookmarks')).toHaveClass('sr-only')
  })
})

describe('ArticleShowSkeleton', () => {
  it('renders article show placeholders with an accessible loading label', () => {
    render(<ArticleShowSkeleton />)
    expect(screen.getByTestId('article-show-skeleton')).toBeInTheDocument()
    expect(screen.getByText('Loading article')).toHaveClass('sr-only')
  })
})
