import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import AppShell from './AppShell'

function renderShell(initialPath = '/') {
  return render(
    <MemoryRouter initialEntries={[initialPath]}>
      <AppShell>
        <div>Page content</div>
      </AppShell>
    </MemoryRouter>
  )
}

describe('AppShell', () => {
  it('renders desktop nav with all main sections', () => {
    renderShell()
    const nav = screen.getByTestId('app-nav')
    expect(nav).toBeInTheDocument()
    expect(screen.getByTestId('app-nav-feed')).toHaveTextContent('Feed')
    expect(screen.getByTestId('app-nav-saved')).toHaveTextContent('Reading List')
    expect(screen.getByTestId('app-nav-read')).toHaveTextContent('Already Read')
    expect(screen.getByTestId('app-nav-dismissed')).toHaveTextContent('Recently Dismissed')
  })

  it('highlights Feed on articles index', () => {
    renderShell('/articles')
    expect(screen.getByTestId('app-nav-feed').className).toMatch(/primary/)
  })

  it('highlights Reading List on bookmarks page', () => {
    renderShell('/bookmarks')
    expect(screen.getByTestId('app-nav-saved').className).toMatch(/primary/)
  })

  it('highlights Dismissed on all dismissed page', () => {
    renderShell('/dismissed')
    expect(screen.getByTestId('app-nav-dismissed').className).toMatch(/primary/)
  })

  it('renders mobile bottom nav', () => {
    renderShell()
    expect(screen.getByTestId('app-nav-mobile')).toBeInTheDocument()
    expect(screen.getByTestId('app-nav-mobile-feed')).toBeInTheDocument()
  })
})
