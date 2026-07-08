import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import Breadcrumbs from './Breadcrumbs'

describe('Breadcrumbs', () => {
  it('renders linked ancestors and plain text for the current page', () => {
    render(
      <MemoryRouter>
        <Breadcrumbs
          items={[
            { label: 'Feed', to: '/' },
            { label: 'Reading List' },
          ]}
        />
      </MemoryRouter>
    )

    expect(screen.getByRole('navigation', { name: 'Breadcrumb' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Feed' })).toHaveAttribute('href', '/')
    expect(screen.getByText('Reading List')).toHaveAttribute('aria-current', 'page')
    expect(screen.queryByRole('link', { name: 'Reading List' })).not.toBeInTheDocument()
  })

  it('renders a three-level trail for dismissed pages', () => {
    render(
      <MemoryRouter>
        <Breadcrumbs
          items={[
            { label: 'Feed', to: '/' },
            { label: 'Recently Dismissed', to: '/recently_dismissed' },
            { label: 'All Dismissed' },
          ]}
        />
      </MemoryRouter>
    )

    expect(screen.getByRole('link', { name: 'Recently Dismissed' })).toHaveAttribute(
      'href',
      '/recently_dismissed'
    )
    expect(screen.getAllByText('All Dismissed')[0]).toHaveAttribute('aria-current', 'page')
  })

  it('collapses to back link and current page on mobile for long trails', () => {
    render(
      <MemoryRouter>
        <Breadcrumbs
          items={[
            { label: 'Feed', to: '/' },
            { label: 'Recently Dismissed', to: '/recently_dismissed' },
            { label: 'All Dismissed' },
          ]}
        />
      </MemoryRouter>
    )

    expect(screen.getByTestId('breadcrumbs-mobile')).toBeInTheDocument()
    expect(screen.getByTestId('breadcrumbs-back')).toHaveAttribute('href', '/recently_dismissed')
    expect(screen.getByTestId('breadcrumbs-back')).toHaveTextContent('← Back')
  })
})
