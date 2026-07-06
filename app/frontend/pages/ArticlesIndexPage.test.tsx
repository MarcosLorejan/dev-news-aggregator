import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ArticlesIndexPage from '../pages/ArticlesIndexPage'
import * as articlesApi from '../api/articles'
import { buildArticlesIndexResponse } from '../test/fixtures'

vi.mock('../api/articles', () => ({
  fetchArticles: vi.fn(),
  dismissArticle: vi.fn(),
  undismissArticle: vi.fn(),
  bookmarkArticle: vi.fn(),
  unbookmarkArticle: vi.fn(),
  markArticleAsRead: vi.fn(),
  unmarkArticleAsRead: vi.fn(),
  fetchNews: vi.fn(),
}))

function renderPage(initialEntries = ['/articles']) {
  return render(
    <MemoryRouter initialEntries={initialEntries}>
      <ArticlesIndexPage />
    </MemoryRouter>
  )
}

async function waitForArticlesFeed() {
  await screen.findByTestId('articles-page')
  await waitFor(() => {
    expect(screen.getAllByRole('button', { name: 'Dismiss article' }).length).toBeGreaterThan(0)
  })
}

describe('ArticlesIndexPage dismiss flow', () => {
  beforeEach(() => {
    vi.mocked(articlesApi.fetchArticles).mockResolvedValue(buildArticlesIndexResponse())
    vi.mocked(articlesApi.dismissArticle).mockResolvedValue({ status: 'dismissed', timeout: 15 })
    vi.mocked(articlesApi.undismissArticle).mockResolvedValue({ status: 'restored' })
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.useRealTimers()
  })

  it('dismisses an article and shows undo toast', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitForArticlesFeed()
    await user.click(screen.getAllByRole('button', { name: 'Dismiss article' })[0])

    await waitFor(() => expect(articlesApi.dismissArticle).toHaveBeenCalledWith(1))

    const toast = screen.getByRole('status')
    expect(toast).toHaveTextContent('Article dismissed')
    expect(toast).toHaveTextContent('Rust 2024 Edition Highlights')
  })

  it('undoes dismiss from toast', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitForArticlesFeed()
    await user.click(screen.getAllByRole('button', { name: 'Dismiss article' })[0])

    const toast = await screen.findByRole('status')
    await user.click(within(toast).getByRole('button', { name: 'Undo dismiss' }))

    await waitFor(() => expect(articlesApi.undismissArticle).toHaveBeenCalledWith(1))
    expect(screen.queryByRole('status')).not.toBeInTheDocument()
  })

  it('filters articles when category changes in the URL', async () => {
    const user = userEvent.setup()
    renderPage(['/articles?category=programming-languages'])

    await waitForArticlesFeed()
    expect(screen.getByText('Rust 2024 Edition Highlights')).toBeInTheDocument()
    expect(screen.queryByText('Ruby 3.3 Performance Tips')).not.toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /All Articles/ }))

    await waitFor(() => {
      expect(screen.getByText('Ruby 3.3 Performance Tips')).toBeInTheDocument()
    })
  })

  it('counts down dismiss toast and removes article after timeout', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    const user = userEvent.setup()

    renderPage()
    await waitForArticlesFeed()

    await user.click(screen.getAllByRole('button', { name: 'Dismiss article' })[0])

    const toast = await screen.findByRole('status')
    expect(toast).toHaveTextContent('15s remaining')

    await vi.advanceTimersByTimeAsync(15_000)

    await waitFor(() => {
      expect(screen.queryByRole('status')).not.toBeInTheDocument()
      expect(screen.queryByText('Rust 2024 Edition Highlights')).not.toBeInTheDocument()
    })
  })
})
