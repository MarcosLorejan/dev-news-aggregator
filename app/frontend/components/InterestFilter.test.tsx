import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import InterestFilter, { parseInterests, toggleInterest } from '../components/InterestFilter'
import { buildKeywordFilter } from '../test/fixtures'

const interests = [
  buildKeywordFilter(),
  buildKeywordFilter({ id: 2, name: 'Rust', slug: 'rust', terms: ['rust'], article_count: 5 }),
]

describe('InterestFilter', () => {
  it('renders one chip per interest with its article count', () => {
    render(
      <InterestFilter interests={interests} selectedSlugs={[]} onToggle={vi.fn()} onClear={vi.fn()} />
    )

    expect(screen.getByRole('button', { name: 'Ruby (3)' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Rust (5)' })).toBeInTheDocument()
  })

  it('omits the count when the API does not provide one', () => {
    render(
      <InterestFilter
        interests={[buildKeywordFilter({ article_count: null })]}
        selectedSlugs={[]}
        onToggle={vi.fn()}
        onClear={vi.fn()}
      />
    )

    expect(screen.getByRole('button', { name: 'Ruby' })).toBeInTheDocument()
  })

  it('marks selected interests with aria-pressed', () => {
    render(
      <InterestFilter
        interests={interests}
        selectedSlugs={['rust']}
        onToggle={vi.fn()}
        onClear={vi.fn()}
      />
    )

    expect(screen.getByRole('button', { name: 'Ruby (3)' })).toHaveAttribute('aria-pressed', 'false')
    expect(screen.getByRole('button', { name: 'Rust (5)' })).toHaveAttribute('aria-pressed', 'true')
  })

  it('calls onToggle with the chip slug', async () => {
    const user = userEvent.setup()
    const onToggle = vi.fn()
    render(
      <InterestFilter interests={interests} selectedSlugs={[]} onToggle={onToggle} onClear={vi.fn()} />
    )

    await user.click(screen.getByRole('button', { name: 'Rust (5)' }))

    expect(onToggle).toHaveBeenCalledWith('rust')
  })

  it('shows the clear affordance only while something is selected', async () => {
    const user = userEvent.setup()
    const onClear = vi.fn()
    const { rerender } = render(
      <InterestFilter interests={interests} selectedSlugs={[]} onToggle={vi.fn()} onClear={onClear} />
    )

    expect(screen.queryByTestId('clear-interests')).not.toBeInTheDocument()

    rerender(
      <InterestFilter
        interests={interests}
        selectedSlugs={['ruby']}
        onToggle={vi.fn()}
        onClear={onClear}
      />
    )

    await user.click(screen.getByTestId('clear-interests'))
    expect(onClear).toHaveBeenCalled()
  })

  it('renders nothing when there are no interests', () => {
    const { container } = render(
      <InterestFilter interests={[]} selectedSlugs={[]} onToggle={vi.fn()} onClear={vi.fn()} />
    )

    expect(container).toBeEmptyDOMElement()
  })
})

describe('parseInterests', () => {
  it('splits, trims, downcases and dedupes slugs', () => {
    expect(parseInterests(' Ruby, rust ,ruby')).toEqual(['ruby', 'rust'])
  })

  it('returns an empty list for missing or blank values', () => {
    expect(parseInterests(null)).toEqual([])
    expect(parseInterests(' , ')).toEqual([])
  })
})

describe('toggleInterest', () => {
  it('adds a slug that is not selected yet', () => {
    expect(toggleInterest(['ruby'], 'rust')).toEqual(['ruby', 'rust'])
  })

  it('removes a slug that is already selected', () => {
    expect(toggleInterest(['ruby', 'rust'], 'ruby')).toEqual(['rust'])
  })
})
