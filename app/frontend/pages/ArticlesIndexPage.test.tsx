import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ArticlesIndexPage from '../pages/ArticlesIndexPage'
import * as articlesApi from '../api/articles'
import * as keywordFiltersApi from '../api/keywordFilters'
import {
  buildArticle,
  buildArticlesIndexResponse,
  buildKeywordFiltersResponse,
} from '../test/fixtures'

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

vi.mock('../api/keywordFilters', () => ({
  fetchKeywordFilters: vi.fn(),
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

async function openFiltersMenu(user: ReturnType<typeof userEvent.setup>) {
  await user.click(screen.getByTestId('filters-menu'))
  return screen.findByTestId('filters-menu-panel')
}

async function openSortMenu(user: ReturnType<typeof userEvent.setup>) {
  await user.click(screen.getByTestId('sort-menu'))
  return screen.findByTestId('sort-menu-panel')
}

describe('ArticlesIndexPage dismiss flow', () => {
  beforeEach(() => {
    vi.mocked(articlesApi.fetchArticles).mockResolvedValue(buildArticlesIndexResponse())
    vi.mocked(articlesApi.dismissArticle).mockResolvedValue({ status: 'dismissed', timeout: 15 })
    vi.mocked(articlesApi.undismissArticle).mockResolvedValue({ status: 'restored' })
    vi.mocked(keywordFiltersApi.fetchKeywordFilters).mockResolvedValue(buildKeywordFiltersResponse())
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
    expect(screen.getByTestId('active-filter-chips')).toHaveTextContent('Programming Languages')

    vi.mocked(articlesApi.fetchArticles).mockResolvedValue(buildArticlesIndexResponse())
    const filters = await openFiltersMenu(user)
    await user.click(within(filters).getByRole('button', { name: /All Articles/ }))

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
    const user = userEvent.setup()
    renderPage(['/articles?sort=score'])

    await waitForArticlesFeed()
    expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
      expect.objectContaining({ sort: 'score' })
    )
    expect(screen.getByTestId('sort-menu')).toHaveTextContent('Highest score')
    const sortPanel = await openSortMenu(user)
    expect(within(sortPanel).getByRole('button', { name: 'Highest score' })).toHaveAttribute(
      'aria-pressed',
      'true'
    )
  })

  it('requests for_you sort when selected', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitForArticlesFeed()
    const sortPanel = await openSortMenu(user)
    await user.click(within(sortPanel).getByRole('button', { name: 'For you' }))

    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
        expect.objectContaining({ sort: 'for_you' })
      )
    })
    expect(screen.getByTestId('sort-menu')).toHaveTextContent('For you')
  })

  it('updates sort via the sort control', async () => {
    const user = userEvent.setup()
    renderPage()

    await waitForArticlesFeed()
    const sortPanel = await openSortMenu(user)
    await user.click(within(sortPanel).getByRole('button', { name: 'Most comments' }))

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

  it('renders interest chips and reflects the interests URL param', async () => {
    const user = userEvent.setup()
    renderPage(['/articles?interests=rust'])

    await waitForArticlesFeed()
    expect(screen.getByTestId('active-filter-chips')).toHaveTextContent('Rust')
    const filters = await openFiltersMenu(user)
    await waitFor(() => {
      expect(within(filters).getByRole('button', { name: 'Rust (5)' })).toHaveAttribute(
        'aria-pressed',
        'true'
      )
    })
    expect(within(filters).getByRole('button', { name: 'Ruby (3)' })).toHaveAttribute(
      'aria-pressed',
      'false'
    )
    expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
      expect.objectContaining({ interests: ['rust'] })
    )
  })

  it('adds and removes interests from the request as chips are toggled', async () => {
    const user = userEvent.setup()
    renderPage(['/articles?interests=rust'])

    await waitForArticlesFeed()
    const filters = await openFiltersMenu(user)
    await user.click(await within(filters).findByRole('button', { name: 'Ruby (3)' }))

    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
        expect.objectContaining({ interests: ['rust', 'ruby'] })
      )
    })

    await user.click(screen.getByRole('button', { name: 'Clear filter Rust' }))

    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
        expect.objectContaining({ interests: ['ruby'] })
      )
    })
  })

  it('clears interests and resets pagination', async () => {
    const user = userEvent.setup()
    renderPage(['/articles?interests=ruby,rust&page=3'])

    await waitForArticlesFeed()
    const filters = await openFiltersMenu(user)
    await user.click(await within(filters).findByTestId('clear-interests'))

    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
        expect.objectContaining({ interests: undefined, page: 1 })
      )
    })
    expect(screen.queryByTestId('clear-interests')).not.toBeInTheDocument()
    expect(screen.queryByTestId('active-filter-chips')).not.toBeInTheDocument()
  })

  it('shows an interest-specific empty state when nothing matches', async () => {
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

    const user = userEvent.setup()
    renderPage(['/articles?interests=rust'])

    await screen.findByTestId('articles-page')
    expect(await screen.findByText('No articles match these interests')).toBeInTheDocument()
    expect(screen.queryByText('Your feed is empty')).not.toBeInTheDocument()
    expect(screen.getByTestId('active-filter-chips')).toHaveTextContent('Rust')
    const filters = await openFiltersMenu(user)
    await waitFor(() => {
      expect(within(filters).getByRole('button', { name: 'Rust (5)' })).toBeInTheDocument()
    })
  })

  it('keeps the feed usable when interests fail to load', async () => {
    vi.mocked(keywordFiltersApi.fetchKeywordFilters).mockRejectedValue(new Error('boom'))

    const user = userEvent.setup()
    renderPage()

    await waitForArticlesFeed()
    const filters = await openFiltersMenu(user)
    expect(within(filters).queryByText('Filter by interest')).not.toBeInTheDocument()
    expect(screen.getByText('Rust 2024 Edition Highlights')).toBeInTheDocument()
  })

  it('applies content_type and max_duration from the URL', async () => {
    const user = userEvent.setup()
    renderPage(['/articles?content_type=video&max_duration=20'])

    await waitForArticlesFeed()
    expect(screen.getByTestId('active-filter-chips')).toHaveTextContent('Videos')
    expect(screen.getByTestId('active-filter-chips')).toHaveTextContent('≤ 20 min')
    const filters = await openFiltersMenu(user)
    expect(within(filters).getByRole('button', { name: 'Videos' })).toHaveAttribute(
      'aria-pressed',
      'true'
    )
    expect(within(filters).getByRole('button', { name: '≤ 20 min' })).toHaveAttribute(
      'aria-pressed',
      'true'
    )
    expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
      expect.objectContaining({ content_type: 'video', max_duration: 20 })
    )
  })

  it('keeps content filters visible when Videos has no matches', async () => {
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

    const user = userEvent.setup()
    renderPage(['/articles?content_type=video'])

    await screen.findByTestId('articles-page')
    expect(await screen.findByText('No videos found')).toBeInTheDocument()
    expect(screen.queryByText('Your feed is empty')).not.toBeInTheDocument()
    expect(screen.getByTestId('active-filter-chips')).toHaveTextContent('Videos')

    const filters = await openFiltersMenu(user)
    expect(within(filters).getByRole('button', { name: 'Videos' })).toHaveAttribute(
      'aria-pressed',
      'true'
    )
    expect(within(filters).getByRole('button', { name: 'All' })).toBeInTheDocument()

    await user.click(within(filters).getByRole('button', { name: 'All' }))

    await waitFor(() => {
      const calls = vi.mocked(articlesApi.fetchArticles).mock.calls
      const lastCall = calls[calls.length - 1]?.[0] as {
        content_type?: string
        page?: number
      }
      expect(lastCall?.page).toBe(1)
      expect(lastCall?.content_type).toBeUndefined()
    })
  })

  it('updates content type params and resets pagination', async () => {
    const user = userEvent.setup()
    renderPage(['/articles?page=3'])

    await waitForArticlesFeed()
    const filters = await openFiltersMenu(user)
    await user.click(within(filters).getByRole('button', { name: 'Videos' }))

    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenCalledWith(
        expect.objectContaining({ content_type: 'video', page: 1 })
      )
    })
  })

  it('clears all active filters from the toolbar summary', async () => {
    const user = userEvent.setup()
    renderPage(['/articles?interests=rust&score=100&content_type=video&category=programming-languages'])

    await waitForArticlesFeed()
    expect(screen.getByTestId('active-filter-chips')).toBeInTheDocument()
    await user.click(screen.getByTestId('clear-all-filters'))

    await waitFor(() => {
      expect(articlesApi.fetchArticles).toHaveBeenLastCalledWith(
        expect.objectContaining({
          interests: undefined,
          category: undefined,
          page: 1,
        })
      )
    })
    const calls = vi.mocked(articlesApi.fetchArticles).mock.calls
    const lastCall = calls[calls.length - 1]?.[0]
    expect(lastCall).not.toHaveProperty('content_type')
    expect(lastCall).not.toHaveProperty('min_score')
    expect(screen.queryByTestId('active-filter-chips')).not.toBeInTheDocument()
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
