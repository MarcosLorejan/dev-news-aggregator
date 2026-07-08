import { Outlet } from 'react-router-dom'
import { FOCUS_RING } from './ui/buttonStyles'
import AppShell from './AppShell'

export default function AppLayout() {
  return (
    <>
      <a
        href="#main-content"
        className={`sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-primary-600 focus:text-white focus:rounded-lg ${FOCUS_RING}`}
      >
        Skip to main content
      </a>
      <AppShell>
        <main id="main-content" className="flex-1 pb-20 md:pb-0">
          <Outlet />
        </main>
      </AppShell>
    </>
  )
}
