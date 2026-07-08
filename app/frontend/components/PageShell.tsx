import type { ReactNode } from 'react'
import ArticleListSkeleton from './ArticleListSkeleton'
import PageContainer from './ui/PageContainer'
import ErrorRetry from './ErrorRetry'

interface PageShellProps {
  testId: string
  loading: boolean
  loadingMessage: string
  error: string | null
  showFatalError: boolean
  onRetry: () => void
  loadingSkeleton?: ReactNode
  children: ReactNode
}

export default function PageShell({
  testId,
  loading,
  loadingMessage,
  error,
  showFatalError,
  onRetry,
  loadingSkeleton,
  children,
}: PageShellProps) {
  if (loading) {
    return (
      <PageContainer testId={testId} role="status" aria-live="polite" aria-busy>
        {loadingSkeleton ?? <ArticleListSkeleton label={loadingMessage} />}
      </PageContainer>
    )
  }

  if (showFatalError && error) {
    return (
      <PageContainer testId={testId} centered>
        <ErrorRetry message={error} onRetry={onRetry} />
      </PageContainer>
    )
  }

  return <PageContainer testId={testId}>{children}</PageContainer>
}
