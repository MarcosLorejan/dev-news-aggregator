import type { ReactNode } from 'react'
import { NavLink, useLocation } from 'react-router-dom'
import { cn } from '../utils/cn'
import { FOCUS_RING } from './ui/buttonStyles'

interface NavItem {
  to: string
  label: string
  shortLabel: string
  isActive: (pathname: string) => boolean
  icon: ReactNode
}

const navItems: NavItem[] = [
  {
    to: '/',
    label: 'Feed',
    shortLabel: 'Feed',
    isActive: (pathname) => pathname === '/' || pathname === '/articles',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9.5a2.5 2.5 0 00-2.5-2.5H15" />
      </svg>
    ),
  },
  {
    to: '/bookmarks',
    label: 'Reading List',
    shortLabel: 'Saved',
    isActive: (pathname) => pathname.startsWith('/bookmarks'),
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
      </svg>
    ),
  },
  {
    to: '/read',
    label: 'Already Read',
    shortLabel: 'Read',
    isActive: (pathname) => pathname.startsWith('/read'),
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
  {
    to: '/recently_dismissed',
    label: 'Recently Dismissed',
    shortLabel: 'Dismissed',
    isActive: (pathname) =>
      pathname.startsWith('/recently_dismissed') || pathname.startsWith('/dismissed'),
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
]

function desktopLinkClassName(isActive: boolean) {
  return [
    'px-3 py-2 rounded-lg text-sm font-medium transition-colors duration-200',
    FOCUS_RING,
    isActive
      ? 'bg-primary-600/20 text-primary-300 ring-1 ring-primary-500/40'
      : 'text-gray-400 hover:text-gray-200 hover:bg-dark-700/60',
  ].join(' ')
}

function mobileLinkClassName(isActive: boolean) {
  return [
    'flex flex-1 flex-col items-center justify-center gap-1 py-2 text-xs font-medium transition-colors duration-200',
    FOCUS_RING,
    isActive ? 'text-primary-400' : 'text-gray-500 hover:text-gray-300',
  ].join(' ')
}

interface AppShellProps {
  children: ReactNode
}

export default function AppShell({ children }: AppShellProps) {
  const { pathname } = useLocation()

  return (
    <div className="min-h-screen flex flex-col">
      <header className="sticky top-0 z-40 surface-elevated border-b border-dark-700/50">
        <div className="container mx-auto px-4 max-w-7xl">
          <div className="hidden md:flex items-center justify-between h-14">
            <NavLink
              to="/"
              className={cn(
                'text-h3 font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent shrink-0',
                FOCUS_RING,
                'rounded-lg'
              )}
            >
              Dev News
            </NavLink>
            <nav aria-label="Main navigation" data-testid="app-nav" className="flex items-center gap-1">
              {navItems.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === '/'}
                  className={() => desktopLinkClassName(item.isActive(pathname))}
                  data-testid={`app-nav-${item.shortLabel.toLowerCase()}`}
                >
                  {item.label}
                </NavLink>
              ))}
            </nav>
          </div>
          <div className="flex md:hidden items-center justify-center h-12">
            <NavLink
              to="/"
              className={cn(
                'text-h3 font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent',
                FOCUS_RING,
                'rounded-lg'
              )}
            >
              Dev News
            </NavLink>
          </div>
        </div>
      </header>

      {children}

      <nav
        aria-label="Mobile navigation"
        data-testid="app-nav-mobile"
        className="md:hidden fixed bottom-0 inset-x-0 z-40 surface-elevated border-t border-dark-700/50 safe-area-pb"
      >
        <div className="flex items-stretch h-16">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={() => mobileLinkClassName(item.isActive(pathname))}
              data-testid={`app-nav-mobile-${item.shortLabel.toLowerCase()}`}
              aria-label={item.label}
            >
              {item.icon}
              <span>{item.shortLabel}</span>
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  )
}
