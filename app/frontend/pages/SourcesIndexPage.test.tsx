import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import SourcesIndexPage from '../pages/SourcesIndexPage'
import * as sourcesApi from '../api/sources'
import { buildNewsSource, buildSourcesIndexResponse } from '../test/fixtures'

vi.mock('../api/sources', () => ({
  fetchSources: vi.fn(),
  updateSource: vi.fn(),
  addRedditSource: vi.fn(),
  removeSource: vi.fn(),
}))

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/sources']}>
      <SourcesIndexPage />
    </MemoryRouter>
  )
}

async function waitForSourcesPage() {
  await screen.findByTestId('sources-page')
  await screen.findByRole('heading', { name: 'News Sources' })
}

describe('SourcesIndexPage', () => {
  beforeEach(() => {
    vi.mocked(sourcesApi.fetchSources).mockResolvedValue(buildSourcesIndexResponse())
    vi.mocked(sourcesApi.updateSource).mockImplementation(async (id, active) =>
      buildNewsSource({
        id,
        active,
        source_type: id === 3 ? 'reddit' : 'hacker_news',
        name: id === 3 ? 'rust' : 'Hacker News',
        subreddit: id === 3 ? 'rust' : null,
      })
    )
    vi.mocked(sourcesApi.addRedditSource).mockResolvedValue(
      buildNewsSource({
        id: 4,
        name: 'programming',
        source_type: 'reddit',
        subreddit: 'programming',
        active: true,
      })
    )
    vi.mocked(sourcesApi.removeSource).mockResolvedValue(undefined)
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('loads and displays built-in and Reddit sources', async () => {
    renderPage()

    await waitForSourcesPage()

    expect(screen.getByText('Hacker News')).toBeInTheDocument()
    expect(screen.getByText('DEV.to')).toBeInTheDocument()
    expect(screen.getByText('r/rust')).toBeInTheDocument()
    expect(screen.getByTestId('source-toggle-hacker_news')).toBeChecked()
    expect(screen.getByTestId('source-toggle-dev_to')).not.toBeChecked()
  })

  it('shows an error when sources fail to load', async () => {
    vi.mocked(sourcesApi.fetchSources).mockRejectedValue(new Error('network'))

    renderPage()

    expect(await screen.findByText('Failed to load news sources.')).toBeInTheDocument()
  })

  it('toggles a built-in source', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForSourcesPage()

    await user.click(screen.getByTestId('source-toggle-hacker_news'))

    await waitFor(() => {
      expect(sourcesApi.updateSource).toHaveBeenCalledWith(1, false)
    })
  })

  it('adds a Reddit subreddit', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForSourcesPage()

    await user.type(screen.getByTestId('subreddit-input'), 'programming')
    await user.click(screen.getByTestId('add-subreddit-button'))

    await waitFor(() => {
      expect(sourcesApi.addRedditSource).toHaveBeenCalledWith('programming')
    })
    expect(await screen.findByText('r/programming')).toBeInTheDocument()
    expect(screen.getByTestId('subreddit-input')).toHaveValue('')
  })

  it('shows validation error when adding a subreddit fails', async () => {
    vi.mocked(sourcesApi.addRedditSource).mockRejectedValue(new Error('Subreddit not found'))
    const user = userEvent.setup()
    renderPage()
    await waitForSourcesPage()

    await user.type(screen.getByTestId('subreddit-input'), 'notarealsub')
    await user.click(screen.getByTestId('add-subreddit-button'))

    expect(await screen.findByTestId('subreddit-validation-error')).toHaveTextContent(
      'Subreddit not found'
    )
  })

  it('removes a Reddit source after confirmation', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForSourcesPage()

    await user.click(screen.getByRole('button', { name: 'Remove' }))
    expect(await screen.findByTestId('confirm-dialog')).toBeInTheDocument()
    await user.click(screen.getByTestId('confirm-dialog-confirm'))

    await waitFor(() => {
      expect(sourcesApi.removeSource).toHaveBeenCalledWith(3)
    })
    expect(screen.queryByText('r/rust')).not.toBeInTheDocument()
  })
})
