import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import CategoryFilter from '../components/CategoryFilter'

describe('CategoryFilter', () => {
  const categories = [
    { name: 'Programming Languages', icon: '🔨' },
    { name: 'Frameworks', icon: '🧱' },
  ]

  it('exposes active filter state with aria-pressed', () => {
    render(
      <CategoryFilter
        categories={categories}
        categoryCounts={{ 'Programming Languages': 3, Frameworks: 1 }}
        totalCount={4}
        activeFilter="programming-languages"
        onFilterChange={vi.fn()}
      />
    )

    expect(screen.getByRole('button', { name: /All Articles/ })).toHaveAttribute('aria-pressed', 'false')
    expect(screen.getByRole('button', { name: /Programming Languages/ })).toHaveAttribute(
      'aria-pressed',
      'true'
    )
    expect(screen.getByRole('button', { name: /Frameworks/ })).toHaveAttribute('aria-pressed', 'false')
  })

  it('calls onFilterChange with category slug when a category is selected', async () => {
    const user = userEvent.setup()
    const onFilterChange = vi.fn()

    render(
      <CategoryFilter
        categories={categories}
        categoryCounts={{ 'Programming Languages': 3, Frameworks: 1 }}
        totalCount={4}
        activeFilter="all"
        onFilterChange={onFilterChange}
      />
    )

    await user.click(screen.getByRole('button', { name: /Frameworks \(1\)/ }))
    expect(onFilterChange).toHaveBeenCalledWith('frameworks')
  })
})
