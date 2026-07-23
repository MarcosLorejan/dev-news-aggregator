import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import BookmarksIndexPage from '../pages/BookmarksIndexPage'
import * as bookmarksApi from '../api/bookmarks'
import * as articlesApi from '../api/articles'
import { buildBookmarksIndexResponse } from '../test/fixtures'

vi.mock('../api/bookmarks', () => ({
  fetchBookmarks: vi.fn(),
}))

vi.mock('../api/articles', () => ({
  unbookmarkArticle: vi.fn(),
  markArticleAsRead: vi.fn(),
  unmarkArticleAsRead: vi.fn(),
}))

function renderPage(initialEntries = ['/bookmarks']) {
  return render(
    <MemoryRouter initialEntries={initialEntries}>
      <BookmarksIndexPage />
    </MemoryRouter>
  )
}

async function waitForBookmarksFeed() {
  await screen.findByTestId('bookmarks-page')
  await waitFor(() => {
    expect(screen.getAllByRole('button', { name: 'Remove from reading list' }).length).toBeGreaterThan(
      0
    )
  })
}

describe('BookmarksIndexPage', () => {
  beforeEach(() => {
    vi.mocked(bookmarksApi.fetchBookmarks).mockResolvedValue(buildBookmarksIndexResponse())
    vi.mocked(articlesApi.unbookmarkArticle).mockResolvedValue({ bookmarked: false })
    vi.mocked(articlesApi.markArticleAsRead).mockResolvedValue({ read: true })
    vi.mocked(articlesApi.unmarkArticleAsRead).mockResolvedValue({ read: false })
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('loads and displays bookmarked articles', async () => {
    renderPage()

    await waitForBookmarksFeed()

    expect(screen.getByRole('heading', { name: 'Reading List' })).toBeInTheDocument()
    expect(screen.getByText('Rust 2024 Edition Highlights')).toBeInTheDocument()
    expect(screen.getByText('Ruby 3.3 Performance Tips')).toBeInTheDocument()
    expect(screen.getByText(/Bookmarked:/)).toHaveTextContent('2')
  })

  it('shows empty state when there are no bookmarks', async () => {
    vi.mocked(bookmarksApi.fetchBookmarks).mockResolvedValue(
      buildBookmarksIndexResponse({
        articles: [],
        articles_by_source: {},
        pagination: {
          current_page: 1,
          per_page: 20,
          total_count: 0,
          total_pages: 0,
        },
      })
    )

    renderPage()

    expect(await screen.findByText('No bookmarked articles yet')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Browse Articles/i })).toHaveAttribute('href', '/articles')
  })

  it('shows a fatal error with retry when loading fails', async () => {
    vi.mocked(bookmarksApi.fetchBookmarks).mockRejectedValueOnce(new Error('network'))
    vi.mocked(bookmarksApi.fetchBookmarks).mockResolvedValueOnce(buildBookmarksIndexResponse())
    const user = userEvent.setup()

    renderPage()

    expect(await screen.findByText('Failed to load reading list. Please try again.')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Retry' }))

    await waitForBookmarksFeed()
    expect(bookmarksApi.fetchBookmarks).toHaveBeenCalledTimes(2)
  })

  it('removes a bookmark from the list', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForBookmarksFeed()

    await user.click(screen.getAllByRole('button', { name: 'Remove from reading list' })[0])

    await waitFor(() => {
      expect(articlesApi.unbookmarkArticle).toHaveBeenCalledWith(1)
    })
    expect(screen.queryByText('Rust 2024 Edition Highlights')).not.toBeInTheDocument()
    expect(screen.getByText('Ruby 3.3 Performance Tips')).toBeInTheDocument()
  })

  it('marks a bookmarked article as read', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForBookmarksFeed()

    await user.click(screen.getAllByRole('button', { name: 'Mark as read' })[0])

    await waitFor(() => {
      expect(articlesApi.markArticleAsRead).toHaveBeenCalledWith(1)
    })
    expect(await screen.findByRole('button', { name: 'Mark as unread' })).toBeInTheDocument()
  })

  it('filters bookmarks when source is in the URL', async () => {
    renderPage(['/bookmarks?source=reddit_rust'])

    await waitForBookmarksFeed()

    expect(screen.getByText('Rust 2024 Edition Highlights')).toBeInTheDocument()
    expect(screen.queryByText('Ruby 3.3 Performance Tips')).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Reddit Rust/ })).toHaveAttribute('aria-pressed', 'true')
  })
})
