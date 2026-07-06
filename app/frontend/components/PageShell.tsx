import type { ReactNode } from 'react'
import ErrorRetry from './ErrorRetry'

interface PageShellProps {
  testId: string
  loading: boolean
  loadingMessage: string
  error: string | null
  showFatalError: boolean
  onRetry: () => void
  children: ReactNode
}

export default function PageShell({
  testId,
  loading,
  loadingMessage,
  error,
  showFatalError,
  onRetry,
  children,
}: PageShellProps) {
  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center text-gray-400" data-testid={testId}>
        {loadingMessage}
      </div>
    )
  }

  if (showFatalError && error) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center" data-testid={testId}>
        <ErrorRetry message={error} onRetry={onRetry} />
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl" data-testid={testId}>
      {children}
    </div>
  )
}
