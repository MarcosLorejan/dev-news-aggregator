import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ArticleShowPage from '../pages/ArticleShowPage'
import * as articlesApi from '../api/articles'
import { buildArticle } from '../test/fixtures'

vi.mock('../api/articles', () => ({
  fetchArticle: vi.fn(),
  bookmarkArticle: vi.fn(),
  unbookmarkArticle: vi.fn(),
  markArticleAsRead: vi.fn(),
  unmarkArticleAsRead: vi.fn(),
}))

function renderPage(path = '/articles/1') {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/articles/:id" element={<ArticleShowPage />} />
      </Routes>
    </MemoryRouter>
  )
}

async function waitForArticleShow() {
  await screen.findByTestId('article-show-page')
  await screen.findByRole('heading', { name: 'Rust 2024 Edition Highlights' })
}

describe('ArticleShowPage', () => {
  beforeEach(() => {
    vi.mocked(articlesApi.fetchArticle).mockResolvedValue(buildArticle())
    vi.mocked(articlesApi.bookmarkArticle).mockResolvedValue({ bookmarked: true })
    vi.mocked(articlesApi.unbookmarkArticle).mockResolvedValue({ bookmarked: false })
    vi.mocked(articlesApi.markArticleAsRead).mockResolvedValue({ read: true })
    vi.mocked(articlesApi.unmarkArticleAsRead).mockResolvedValue({ read: false })
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('loads and displays the article details', async () => {
    renderPage()

    await waitForArticleShow()

    expect(articlesApi.fetchArticle).toHaveBeenCalledWith(1)
    expect(screen.getByText('Reddit Rust')).toBeInTheDocument()
    expect(screen.getByText('A summary of Rust changes.')).toBeInTheDocument()
    expect(screen.getByText('120 points')).toBeInTheDocument()
    expect(screen.getByText('8 comments')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Visit Source/i })).toHaveAttribute(
      'href',
      'https://example.com/rust'
    )
  })

  it('auto-marks the article as read when opened if unread', async () => {
    renderPage()
    await waitForArticleShow()

    await waitFor(() => {
      expect(articlesApi.markArticleAsRead).toHaveBeenCalledWith(1)
    })
    expect(screen.getByText('Already Read')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Mark as Unread' })).toBeInTheDocument()
  })

  it('does not auto-mark when the article is already read', async () => {
    vi.mocked(articlesApi.fetchArticle).mockResolvedValue(buildArticle({ read: true }))

    renderPage()
    await waitForArticleShow()

    expect(screen.getByText('Already Read')).toBeInTheDocument()
    expect(articlesApi.markArticleAsRead).not.toHaveBeenCalled()
  })

  it('keeps the article visible when auto-mark as read fails', async () => {
    vi.mocked(articlesApi.markArticleAsRead).mockRejectedValue(new Error('fail'))

    renderPage()
    await waitForArticleShow()

    await waitFor(() => {
      expect(articlesApi.markArticleAsRead).toHaveBeenCalledWith(1)
    })
    expect(screen.getByRole('heading', { name: 'Rust 2024 Edition Highlights' })).toBeInTheDocument()
    expect(screen.queryByText('Already Read')).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Mark as Read' })).toBeInTheDocument()
  })

  it('shows not found when the article cannot be loaded', async () => {
    vi.mocked(articlesApi.fetchArticle).mockRejectedValue(new Error('missing'))

    renderPage()

    expect(await screen.findByText('Article not found.')).toBeInTheDocument()
  })

  it('shows not found for an invalid article id', async () => {
    renderPage('/articles/not-a-number')

    expect(await screen.findByText('Article not found.')).toBeInTheDocument()
    expect(articlesApi.fetchArticle).not.toHaveBeenCalled()
  })

  it('allows marking the article as unread after auto-mark', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForArticleShow()

    await waitFor(() => {
      expect(articlesApi.markArticleAsRead).toHaveBeenCalledWith(1)
    })
    expect(screen.getByText('Already Read')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Mark as Unread' })).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Mark as Unread' }))

    await waitFor(() => {
      expect(articlesApi.unmarkArticleAsRead).toHaveBeenCalledWith(1)
    })
    expect(screen.queryByText('Already Read')).not.toBeInTheDocument()
  })

  it('adds the article to the reading list', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForArticleShow()

    await user.click(screen.getByRole('button', { name: 'Add to Reading List' }))

    await waitFor(() => {
      expect(articlesApi.bookmarkArticle).toHaveBeenCalledWith(1)
    })
    expect(screen.getByText('Bookmarked')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Remove from Reading List' })).toBeInTheDocument()
  })

  it('removes the article from the reading list after confirmation', async () => {
    vi.mocked(articlesApi.fetchArticle).mockResolvedValue(buildArticle({ bookmarked: true }))
    const user = userEvent.setup()
    renderPage()
    await waitForArticleShow()

    await user.click(screen.getByRole('button', { name: 'Remove from Reading List' }))
    expect(await screen.findByTestId('confirm-dialog')).toBeInTheDocument()
    await user.click(screen.getByTestId('confirm-dialog-confirm'))

    await waitFor(() => {
      expect(articlesApi.unbookmarkArticle).toHaveBeenCalledWith(1)
    })
    expect(screen.queryByText('Bookmarked')).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Add to Reading List' })).toBeInTheDocument()
  })

  it('shows an action error when bookmarking fails', async () => {
    vi.mocked(articlesApi.bookmarkArticle).mockRejectedValue(new Error('fail'))
    const user = userEvent.setup()
    renderPage()
    await waitForArticleShow()

    await user.click(screen.getByRole('button', { name: 'Add to Reading List' }))

    expect(await screen.findByText('Failed to update bookmark.')).toBeInTheDocument()
  })
})
