import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ArticlesIndexPage from '../pages/ArticlesIndexPage'
import * as articlesApi from '../api/articles'
import { buildArticle, buildArticlesIndexResponse } from '../test/fixtures'

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

  it('requests filtered articles when category is in the URL', async () => {
    const filtered = buildArticlesIndexResponse({
      articles: [buildArticle()],
      articles_by_category: { 'Programming Languages': [1] },
      category_counts: { 'Programming Languages': 1, Frameworks: 1 },
      pagination: {
        current_page: 1,
        per_page: 20,
        total_count: 1,
        total_pages: 1,
      },
    })
    vi.mocked(articlesApi.fetchArticles).mockResolvedValue(filtered)

    const user = userEvent.setup()
    renderPage(['/articles?category=programming-languages'])

    await waitForArticlesFeed()
    expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
      expect.objectContaining({ category: 'programming-languages' })
    )
    expect(screen.getByText('Rust 2024 Edition Highlights')).toBeInTheDocument()
    expect(screen.queryByText('Ruby 3.3 Performance Tips')).not.toBeInTheDocument()

    vi.mocked(articlesApi.fetchArticles).mockResolvedValue(buildArticlesIndexResponse())
    await user.click(screen.getByRole('button', { name: /All Articles/ }))

    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
        expect.objectContaining({ category: undefined })
      )
    })
    await waitFor(() => {
      expect(screen.getByText('Ruby 3.3 Performance Tips')).toBeInTheDocument()
    })
  })

  it('requests search results when q is in the URL', async () => {
    const filtered = buildArticlesIndexResponse({
      articles: [buildArticle()],
      articles_by_category: { 'Programming Languages': [1] },
      category_counts: { 'Programming Languages': 1 },
      pagination: {
        current_page: 1,
        per_page: 20,
        total_count: 1,
        total_pages: 1,
      },
    })
    vi.mocked(articlesApi.fetchArticles).mockResolvedValue(filtered)

    renderPage(['/articles?q=Rust'])

    await waitForArticlesFeed()
    expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
      expect.objectContaining({ q: 'Rust' })
    )
    expect(screen.getByTestId('article-search-input')).toHaveValue('Rust')
  })

  it('requests sorted articles when sort is in the URL', async () => {
    renderPage(['/articles?sort=score'])

    await waitForArticlesFeed()
    expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
      expect.objectContaining({ sort: 'score' })
    )
    expect(screen.getByRole('button', { name: 'Highest score' })).toHaveAttribute('aria-pressed', 'true')
  })

  it('updates sort via the sort control', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitForArticlesFeed()
    await user.click(screen.getByRole('button', { name: 'Most comments' }))

    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
        expect.objectContaining({ sort: 'comment_count' })
      )
    })
  })

  it('shows an empty search state when no articles match', async () => {
    vi.mocked(articlesApi.fetchArticles).mockResolvedValue(
      buildArticlesIndexResponse({
        articles: [],
        articles_by_category: {},
        category_counts: {},
        pagination: {
          current_page: 1,
          per_page: 20,
          total_count: 0,
          total_pages: 0,
        },
      })
    )

    renderPage(['/articles?q=zzzz-no-match'])

    await screen.findByTestId('articles-page')
    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
        expect.objectContaining({ q: 'zzzz-no-match' })
      )
    })
    expect(screen.getByText('No articles match your search')).toBeInTheDocument()
    expect(screen.queryByText('Your feed is empty')).not.toBeInTheDocument()
    expect(screen.getByTestId('article-search-input')).toHaveValue('zzzz-no-match')
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
