import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import DigestsIndexPage from './DigestsIndexPage'
import * as digestsApi from '../api/digests'
import type { DigestSummary } from '../api/digests'

vi.mock('../api/digests', () => ({
  fetchDigests: vi.fn(),
  createDigest: vi.fn(),
}))

function buildDigest(overrides: Partial<DigestSummary> = {}): DigestSummary {
  return {
    id: 1,
    period: 'daily',
    window_start: '2026-08-01T00:00:00Z',
    window_end: '2026-08-02T00:00:00Z',
    payload: {
      period: 'daily',
      generated_at: '2026-08-02T00:00:00Z',
      window_start: '2026-08-01T00:00:00Z',
      window_end: '2026-08-02T00:00:00Z',
      themes: [{ title: 'General Tech', summary: 'One title', article_ids: [10] }],
      articles: [
        {
          id: 10,
          title: 'Example article',
          url: 'https://example.com/a',
          source_type: 'hacker_news',
          score: 42,
          why: 'Unread from hacker news',
        },
      ],
    },
    created_at: '2026-08-02T00:00:00Z',
    ...overrides,
  }
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/digests']}>
      <DigestsIndexPage />
    </MemoryRouter>
  )
}

describe('DigestsIndexPage', () => {
  beforeEach(() => {
    vi.mocked(digestsApi.fetchDigests).mockResolvedValue({ digests: [] })
    vi.mocked(digestsApi.createDigest).mockResolvedValue(buildDigest())
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('shows empty state when there are no digests', async () => {
    renderPage()

    expect(await screen.findByRole('heading', { name: 'Digests' })).toBeInTheDocument()
    expect(screen.getByText('No digests yet')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Generate daily digest' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Generate weekly digest' })).toBeInTheDocument()
  })

  it('lists digests when the API returns rows', async () => {
    vi.mocked(digestsApi.fetchDigests).mockResolvedValue({ digests: [buildDigest()] })

    renderPage()

    expect(await screen.findByText('daily digest')).toBeInTheDocument()
    expect(screen.getByText('1 articles · 1 themes')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'View digest' })).toHaveAttribute('href', '/digests/1')
  })

  it('surfaces the underlying load error and recovers on retry', async () => {
    vi.mocked(digestsApi.fetchDigests).mockRejectedValueOnce(new Error('Request failed: 500'))
    vi.mocked(digestsApi.fetchDigests).mockResolvedValueOnce({ digests: [] })
    const user = userEvent.setup()

    renderPage()

    expect(await screen.findByText('Request failed: 500')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Retry' }))

    expect(await screen.findByText('No digests yet')).toBeInTheDocument()
    expect(digestsApi.fetchDigests).toHaveBeenCalledTimes(2)
  })

  it('retries once on transient network failure before succeeding', async () => {
    vi.mocked(digestsApi.fetchDigests).mockRejectedValueOnce(new TypeError('Failed to fetch'))
    vi.mocked(digestsApi.fetchDigests).mockResolvedValueOnce({ digests: [] })

    renderPage()

    expect(await screen.findByText('No digests yet')).toBeInTheDocument()
    expect(digestsApi.fetchDigests).toHaveBeenCalledTimes(2)
  })

  it('prepends a generated digest to the list', async () => {
    const user = userEvent.setup()
    renderPage()
    expect(await screen.findByText('No digests yet')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Generate daily digest' }))

    await waitFor(() => {
      expect(digestsApi.createDigest).toHaveBeenCalledWith('daily')
    })
    expect(await screen.findByText('daily digest')).toBeInTheDocument()
  })
})
