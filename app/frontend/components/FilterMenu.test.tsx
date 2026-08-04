import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import FilterMenu from './FilterMenu'

describe('FilterMenu', () => {
  it('opens and closes the panel', async () => {
    const user = userEvent.setup()
    render(
      <FilterMenu label="Filters" testId="filters-menu">
        <button type="button">Inside</button>
      </FilterMenu>
    )

    expect(screen.queryByTestId('filters-menu-panel')).not.toBeInTheDocument()
    await user.click(screen.getByTestId('filters-menu'))
    expect(screen.getByTestId('filters-menu-panel')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Inside' })).toBeInTheDocument()

    await user.keyboard('{Escape}')
    expect(screen.queryByTestId('filters-menu-panel')).not.toBeInTheDocument()
  })

  it('shows an active summary on the trigger', () => {
    render(
      <FilterMenu label="Sort" summary="Newest" active testId="sort-menu">
        <div>options</div>
      </FilterMenu>
    )

    expect(screen.getByTestId('sort-menu')).toHaveTextContent('Sort: Newest')
  })
})
