import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import InterestsIndexPage from '../pages/InterestsIndexPage'
import * as keywordFiltersApi from '../api/keywordFilters'
import { buildKeywordFilter, buildKeywordFiltersResponse } from '../test/fixtures'

vi.mock('../api/keywordFilters', () => ({
  fetchKeywordFilters: vi.fn(),
  createKeywordFilter: vi.fn(),
  updateKeywordFilter: vi.fn(),
  deleteKeywordFilter: vi.fn(),
}))

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/interests']}>
      <InterestsIndexPage />
    </MemoryRouter>
  )
}

async function waitForInterestsPage() {
  await screen.findByTestId('interests-page')
  await screen.findByRole('heading', { name: 'Interests' })
}

describe('InterestsIndexPage', () => {
  beforeEach(() => {
    vi.mocked(keywordFiltersApi.fetchKeywordFilters).mockResolvedValue(buildKeywordFiltersResponse())
    vi.mocked(keywordFiltersApi.createKeywordFilter).mockResolvedValue(
      buildKeywordFilter({
        id: 3,
        name: 'Architecture',
        slug: 'architecture',
        terms: ['software architecture'],
        position: 2,
        article_count: null,
      })
    )
    vi.mocked(keywordFiltersApi.updateKeywordFilter).mockImplementation(async (id, attributes) =>
      buildKeywordFilter({
        id,
        name: id === 1 ? 'Ruby' : 'Rust',
        slug: id === 1 ? 'ruby' : 'rust',
        terms: attributes.terms ?? (id === 1 ? ['ruby', 'rubygems'] : ['rust']),
        active: attributes.active ?? true,
        position: attributes.position ?? (id === 1 ? 0 : 1),
        article_count: id === 1 ? 3 : 5,
      })
    )
    vi.mocked(keywordFiltersApi.deleteKeywordFilter).mockResolvedValue(undefined)
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('loads and displays interests with terms and counts', async () => {
    renderPage()
    await waitForInterestsPage()

    expect(screen.getByText('Ruby')).toBeInTheDocument()
    expect(screen.getByText('Rust')).toBeInTheDocument()
    expect(screen.getByText('3 matching')).toBeInTheDocument()
    expect(screen.getByText('rubygems')).toBeInTheDocument()
  })

  it('creates an interest from the form', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForInterestsPage()

    await user.type(screen.getByTestId('interest-name-input'), 'Architecture')
    await user.type(screen.getByTestId('term-chip-input-field'), 'software architecture{Enter}')
    await user.click(screen.getByTestId('add-interest-button'))

    await waitFor(() => {
      expect(keywordFiltersApi.createKeywordFilter).toHaveBeenCalledWith({
        name: 'Architecture',
        terms: ['software architecture'],
        position: 2,
      })
    })
    expect(await screen.findByText('Architecture')).toBeInTheDocument()
  })

  it('surfaces API validation errors when create fails', async () => {
    vi.mocked(keywordFiltersApi.createKeywordFilter).mockRejectedValue(
      new Error("Name can't be blank, Terms must include at least one keyword")
    )
    const user = userEvent.setup()
    renderPage()
    await waitForInterestsPage()

    await user.type(screen.getByTestId('interest-name-input'), 'Broken')
    await user.type(screen.getByTestId('term-chip-input-field'), 'x{Enter}')
    await user.click(screen.getByTestId('add-interest-button'))

    expect(await screen.findByTestId('interest-validation-error')).toHaveTextContent(
      "Name can't be blank"
    )
  })

  it('edits terms inline and saves them', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForInterestsPage()

    await user.click(screen.getByTestId('edit-interest-ruby'))
    await user.click(screen.getByRole('button', { name: 'Remove rubygems' }))
    await user.type(screen.getByTestId('edit-terms-ruby-field'), 'hotwire{Enter}')
    await user.click(screen.getByTestId('save-terms-ruby'))

    await waitFor(() => {
      expect(keywordFiltersApi.updateKeywordFilter).toHaveBeenCalledWith(1, {
        terms: ['ruby', 'hotwire'],
      })
    })
  })

  it('toggles active state', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForInterestsPage()

    await user.click(screen.getByTestId('interest-toggle-ruby'))

    await waitFor(() => {
      expect(keywordFiltersApi.updateKeywordFilter).toHaveBeenCalledWith(1, { active: false })
    })
  })

  it('deletes an interest after confirmation', async () => {
    const user = userEvent.setup()
    renderPage()
    await waitForInterestsPage()

    await user.click(screen.getByTestId('delete-interest-ruby'))
    expect(await screen.findByTestId('confirm-dialog')).toBeInTheDocument()
    await user.click(screen.getByTestId('confirm-dialog-confirm'))

    await waitFor(() => {
      expect(keywordFiltersApi.deleteKeywordFilter).toHaveBeenCalledWith(1)
    })
    expect(screen.queryByText('Ruby')).not.toBeInTheDocument()
  })

  it('shows an error when interests fail to load', async () => {
    vi.mocked(keywordFiltersApi.fetchKeywordFilters).mockRejectedValue(new Error('network'))

    renderPage()

    expect(await screen.findByText('Failed to load interests.')).toBeInTheDocument()
  })
})
